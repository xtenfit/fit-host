"use client";

import { useSearchParams } from 'next/navigation';
import { FormEvent, useMemo, useState } from 'react';

export default function VerifyClient() {
  const searchParams = useSearchParams();
  const initialEmail = useMemo(() => searchParams.get('email') || '', [searchParams]);
  const [email, setEmail] = useState(initialEmail);
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setLoading(true);
    setStatus(null);

    try {
      const response = await fetch('/api/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, otp }),
      });

      const payload = await response.json();

      if (!response.ok) {
        throw new Error(payload?.error || 'Verification failed.');
      }

      setStatus({
        type: 'success',
        message: 'Email verified successfully. You can now continue securely.',
      });
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
        <h1>Enter your code</h1>
        <p>
          We sent a one-time code to your email. Please enter the 6-digit verification code to continue.
        </p>

        <form onSubmit={handleSubmit} className="verify-form">
          <label>
            Email address
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              required
            />
          </label>

          <label>
            Verification code
            <input
              type="text"
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
              placeholder="123456"
              inputMode="numeric"
              autoComplete="one-time-code"
              required
            />
          </label>

          <button type="submit" disabled={loading}>
            {loading ? 'Verifying...' : 'Verify email'}
          </button>
        </form>

        {status && (
          <div className={status.type === 'success' ? 'status success' : 'status error'}>
            {status.message}
          </div>
        )}

        <div className="verify-meta">Your code expires in a short time for security.</div>
        <a href="/" className="verify-link">← Back to send another verification email</a>
      </section>
    </main>
  );
}
