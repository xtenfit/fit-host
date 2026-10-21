"use client";

import { FormEvent, useState } from 'react';

export default function HomePage() {
  const [form, setForm] = useState({ name: '', email: '', company: '' });
  const [status, setStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);
    setStatus(null);

    try {
      const response = await fetch('/api/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });

      const payload = await response.json();

      if (!response.ok) {
        throw new Error(payload?.error || 'Unable to send verification email.');
      }

      const nextUrl = `/verify?email=${encodeURIComponent(form.email)}`;
      window.location.href = nextUrl;
    } catch (error) {
      setStatus({
        type: 'error',
        message: error instanceof Error ? error.message : 'Something went wrong.',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="page-shell">
      <section className="hero-panel">
        <div className="badge">Verified by design</div>
        <h1>Secure email verification for your clients.</h1>
        <p>
          Send verification emails instantly, prevent fake signups, and confirm identity with a clean, production-ready OTP flow.
        </p>

        <div className="pill-row">
          <span>✅ Real-time OTP</span>
          <span>🔒 Secure API</span>
          <span>📨 Automated email</span>
        </div>

        <div className="alert-box">
          <strong>Important client alert:</strong>
          <p>A one-time verification code is sent immediately after submission.</p>
        </div>
      </section>

      <section className="form-panel">
        <div className="heading">
          <h2>Verify an email</h2>
          <p>Send a secure code to confirm the client’s email address and identity.</p>
        </div>

        <form onSubmit={handleSubmit} className="otp-form">
          <label>
            Full name
            <input
              type="text"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="Jane Smith"
              required
            />
          </label>

          <label>
            Email address
            <input
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              placeholder="jane@company.com"
              required
            />
          </label>

          <label>
            Company / organization
            <input
              type="text"
              value={form.company}
              onChange={(e) => setForm({ ...form, company: e.target.value })}
              placeholder="Amit Rana Studio"
            />
          </label>

          <button type="submit" disabled={loading}>
            {loading ? 'Sending...' : 'Send verification email'}
          </button>
        </form>

        {status && (
          <div className={status.type === 'success' ? 'status success' : 'status error'}>
            {status.message}
          </div>
        )}

        <div className="small-note">Powered by Next.js + Supabase + automated email delivery.</div>
      </section>
    </main>
  );
}
