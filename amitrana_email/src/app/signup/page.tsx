"use client";

import { FormEvent, useState } from 'react';

export default function SignupPage() {
  const [form, setForm] = useState({ name: '', email: '', company: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setStatus(null);

    try {
      const response = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });

      const payload = await response.json();

      if (!response.ok) {
        throw new Error(payload?.error || 'Signup failed.');
      }

      window.location.href = `/verify?email=${encodeURIComponent(form.email)}`;
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
    <main className="verify-shell">
      <section className="verify-card">
        <h1>Create account</h1>
        <p>Sign up, receive your verification code, and confirm your email before accessing your account.</p>

        <form onSubmit={handleSubmit} className="verify-form">
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
            Company
            <input
              type="text"
              value={form.company}
              onChange={(e) => setForm({ ...form, company: e.target.value })}
              placeholder="Amit Rana Studio"
            />
          </label>

          <label>
            Password
            <input
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
              placeholder="Minimum 8 characters"
              required
            />
          </label>

          <button type="submit" disabled={loading}>
            {loading ? 'Creating account...' : 'Create account'}
          </button>
        </form>

        {status && (
          <div className={status.type === 'success' ? 'status success' : 'status error'}>
            {status.message}
          </div>
        )}

        <a href="/" className="verify-link">← Back to home</a>
      </section>
    </main>
  );
}
