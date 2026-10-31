import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../../scripts/cloudflare_supabase_proxy.js';

describe('Cloudflare Supabase Custom Domain Proxy Worker', () => {
  test('returns 200 OK status on root path /', async () => {
    const req = new Request('https://api.amitrana.tech/');
    const res = await worker.fetch(req);
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.status, 'online');
    assert.equal(data.domain, 'api.amitrana.tech');
    assert.equal(data.backend, 'eedubttdylyqrhyeikwb.supabase.co');
  });

  test('handles CORS pre-flight OPTIONS request', async () => {
    const req = new Request('https://api.amitrana.tech/auth/v1/user', {
      method: 'OPTIONS',
    });
    const res = await worker.fetch(req);
    assert.equal(res.status, 204);
    assert.equal(res.headers.get('Access-Control-Allow-Origin'), '*');
  });

  test('worker code specifies redirect manual to prevent proxying Google OAuth', async () => {
    // Intercept fetch to verify Request options
    const originalFetch = globalThis.fetch;
    let interceptedRequest;

    globalThis.fetch = async (req) => {
      interceptedRequest = req;
      return new Response('{}', {
        status: 302,
        headers: {
          location:
            'https://accounts.google.com/o/oauth2/v2/auth?client_id=123&redirect_uri=https%3A%2F%2Feedubttdylyqrhyeikwb.supabase.co%2Fauth%2Fv1%2Fcallback',
        },
      });
    };

    try {
      const req = new Request(
        'https://api.amitrana.tech/auth/v1/authorize?provider=google'
      );
      const res = await worker.fetch(req);

      assert.ok(interceptedRequest, 'Request must be constructed and passed to fetch');
      assert.equal(interceptedRequest.redirect, 'manual', 'Must use redirect: manual');
      assert.equal(
        interceptedRequest.headers.get('x-forwarded-host'),
        'api.amitrana.tech',
        'Must forward X-Forwarded-Host'
      );
      assert.equal(
        interceptedRequest.headers.get('x-forwarded-proto'),
        'https',
        'Must forward X-Forwarded-Proto'
      );

      // Verify that the external 302 redirect to accounts.google.com is preserved
      assert.equal(res.status, 302);
      assert.ok(
        res.headers.get('location').startsWith('https://accounts.google.com'),
        'External OAuth redirect to Google must be passed to client browser'
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  test('rewrites internal Supabase backend redirect location to custom domain', async () => {
    const originalFetch = globalThis.fetch;

    globalThis.fetch = async () => {
      return new Response('{}', {
        status: 302,
        headers: {
          location:
            'https://eedubttdylyqrhyeikwb.supabase.co/auth/v1/verify?token=xyz&type=signup',
        },
      });
    };

    try {
      const req = new Request('https://api.amitrana.tech/auth/v1/verify?token=xyz');
      const res = await worker.fetch(req);

      assert.equal(res.status, 302);
      assert.equal(
        res.headers.get('location'),
        'https://api.amitrana.tech/auth/v1/verify?token=xyz&type=signup',
        'Internal redirect location must be rewritten to api.amitrana.tech'
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  test('converts io.supabase.fithost:// deep link redirects into HTML Intent bridge', async () => {
    const originalFetch = globalThis.fetch;

    globalThis.fetch = async () => {
      return new Response('', {
        status: 302,
        headers: {
          location: 'io.supabase.fithost://login-callback?code=test-auth-code-12345',
        },
      });
    };

    try {
      const req = new Request('https://api.amitrana.tech/auth/v1/callback?code=g-code');
      const res = await worker.fetch(req);

      assert.equal(res.status, 200, 'Must return 200 OK HTML page to prevent Chrome dropping 302');
      assert.ok(res.headers.get('content-type').includes('text/html'));
      const text = await res.text();
      assert.ok(text.includes('Open Fit Host App'));
      assert.ok(text.includes('intent://login-callback?code=test-auth-code-12345#Intent;scheme=io.supabase.fithost;package=com.fithost.fit_host;end;'));
      assert.ok(text.includes('io.supabase.fithost://login-callback?code=test-auth-code-12345'));
    } finally {
      globalThis.fetch = originalFetch;
    }
  });
});

