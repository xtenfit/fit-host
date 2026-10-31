/**
 * Cloudflare Worker: Supabase Reverse Proxy for Custom Domain
 * Custom Domain: https://api.amitrana.tech
 * Target Backend: https://eedubttdylyqrhyeikwb.supabase.co
 *
 * Instructions:
 * 1. Open Cloudflare Dashboard -> Workers & Pages -> dry-recipe-45d3
 * 2. Click "Edit code" (top right)
 * 3. Replace all contents of worker.js with this script
 * 4. Click "Deploy"
 */

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // 1. Root Gateway Status & OAuth Error forwarder
    if (url.pathname === '/' || url.pathname === '') {
      if (url.searchParams.has('error')) {
        const errorDeepLink = `io.supabase.fithost://login-callback${url.search}`;
        return Response.redirect(errorDeepLink, 303);
      }
      return new Response(
        JSON.stringify(
          {
            status: 'online',
            service: 'Fit Host Supabase Gateway',
            domain: 'api.amitrana.tech',
            backend: 'eedubttdylyqrhyeikwb.supabase.co',
            health: 'https://api.amitrana.tech/auth/v1/health',
            timestamp: new Date().toISOString(),
          },
          null,
          2
        ),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // 2. Handle CORS pre-flight OPTIONS requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers':
            'authorization, x-client-info, apikey, content-type, prefer, x-supabase-api-version',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // 3. Forward request to Supabase backend
    const targetUrl = new URL(request.url);
    targetUrl.hostname = 'eedubttdylyqrhyeikwb.supabase.co';
    targetUrl.port = '443';
    targetUrl.protocol = 'https:';

    const newHeaders = new Headers(request.headers);
    newHeaders.set('Host', 'eedubttdylyqrhyeikwb.supabase.co');
    newHeaders.set('X-Forwarded-Host', 'api.amitrana.tech');
    newHeaders.set('X-Forwarded-Proto', 'https');
    const clientIp = request.headers.get('CF-Connecting-IP');
    if (clientIp) {
      newHeaders.set('X-Real-IP', clientIp);
    }

    // In Fetch API / Cloudflare Workers, GET and HEAD methods MUST NOT contain a body.
    const hasBody = !['GET', 'HEAD'].includes(request.method);

    const modifiedRequest = new Request(targetUrl.toString(), {
      method: request.method,
      headers: newHeaders,
      body: hasBody ? request.body : undefined,
      redirect: 'manual',
    });

    try {
      // CRITICAL: redirect: 'manual' is passed in both the Request and fetch init options.
      // This stops Cloudflare from chasing 3xx redirects (such as Google OAuth or verification redirects)
      // which would otherwise render Google's sign-in page under api.amitrana.tech, breaking authentication.
      const response = await fetch(modifiedRequest, {
        redirect: 'manual',
      });

      // Attach CORS headers so Flutter and Web clients can communicate seamlessly
      const newResponseHeaders = new Headers(response.headers);
      newResponseHeaders.set('Access-Control-Allow-Origin', '*');
      newResponseHeaders.set(
        'Access-Control-Allow-Headers',
        'authorization, x-client-info, apikey, content-type, prefer, x-supabase-api-version'
      );
      newResponseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');

      // 4. Handle 3xx Redirects (Preserve external OAuth like Google, rewrite internal Supabase redirects)
      if (response.status >= 300 && response.status < 400) {
        let location = response.headers.get('location');
        if (location) {
          // If the redirect target is an internal app deep link (e.g. io.supabase.fithost://login-callback)
          // Android Chrome security blocks server-side 302 redirects to custom URI schemes without user gesture.
          // Returning an HTML bridge page auto-invokes Chrome Intent syntax and provides a one-tap button fallback.
          if (location.startsWith('io.supabase.fithost://')) {
            const pathAndQuery = location.replace(/^io\.supabase\.fithost:\/\//, '');
            const intentUrl = 'intent://' + pathAndQuery + '#Intent;scheme=io.supabase.fithost;package=com.fithost.fit_host;end;';

            const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fit Host — Authentication Successful</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 0;
      background: #0B0F0D;
      color: #FFFFFF;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      text-align: center;
    }
    .card {
      background: #16251E;
      border: 1.5px solid rgba(163, 230, 53, 0.4);
      border-radius: 28px;
      padding: 40px 24px;
      max-width: 400px;
      width: 90%;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
    }
    .icon-wrap {
      width: 72px;
      height: 72px;
      background: rgba(163, 230, 53, 0.15);
      border: 1.5px solid rgba(163, 230, 53, 0.3);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      font-size: 32px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      margin: 0 0 10px;
      color: #FFFFFF;
    }
    p {
      color: #9CA3AF;
      font-size: 14px;
      line-height: 1.5;
      margin: 0 0 28px;
    }
    .btn {
      display: block;
      width: 100%;
      background: #A3E635;
      color: #000000;
      text-decoration: none;
      font-weight: 800;
      font-size: 16px;
      padding: 16px 24px;
      border-radius: 16px;
      box-shadow: 0 6px 20px rgba(163, 230, 53, 0.25);
      cursor: pointer;
    }
    .status {
      margin-top: 18px;
      font-size: 12px;
      color: #6B7280;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-wrap">⚡</div>
    <h1>Authentication Successful!</h1>
    <p>Connecting your Google account to Fit Host. Tap the button below to return to the app.</p>
    <a id="openAppBtn" class="btn" href="${intentUrl}">Open Fit Host App</a>
    <div class="status">FIT HOST CLOUD SYNC</div>
  </div>

  <script>
    const deepLink = ${JSON.stringify(location)};
    const intentUrl = ${JSON.stringify(intentUrl)};
    const btn = document.getElementById('openAppBtn');

    let hasOpened = false;
    function openApp() {
      if (hasOpened) return;
      hasOpened = true;
      try {
        window.location.replace(intentUrl);
      } catch (e) {
        window.location.href = deepLink;
      }
    }

    // Attempt single automatic navigation
    openApp();

    btn.addEventListener('click', function(e) {
      window.location.href = deepLink;
    });
  </script>
</body>
</html>`;

            newResponseHeaders.set('Content-Type', 'text/html; charset=utf-8');
            newResponseHeaders.set('location', location);
            return new Response(html, {
              status: 200,
              headers: newResponseHeaders,
            });
          }

          try {
            const locUrl = new URL(location);
            // ONLY rewrite if redirect destination host is Supabase itself.
            // NEVER modify query parameters of external OAuth providers (accounts.google.com),
            // because OAuth 2.0 RFC 6749 strictly requires the callback redirect_uri in the
            // token exchange to match the registered callback URL (eedubttdylyqrhyeikwb.supabase.co).
            if (locUrl.hostname === 'eedubttdylyqrhyeikwb.supabase.co') {
              locUrl.hostname = 'api.amitrana.tech';
              location = locUrl.toString();
            }
          } catch (_) {
            // Keep custom schemes (e.g. io.supabase.fithost://login-callback) or relative paths untouched
          }
          newResponseHeaders.set('location', location);
        }

        return new Response(null, {
          status: response.status,
          statusText: response.statusText,
          headers: newResponseHeaders,
        });
      }

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newResponseHeaders,
      });
    } catch (err) {
      return new Response(
        JSON.stringify({
          error: 'Gateway forwarding failed',
          details: err.message,
        }),
        {
          status: 502,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }
  },
};
