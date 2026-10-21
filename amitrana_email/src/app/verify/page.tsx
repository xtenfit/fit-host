import { Suspense } from 'react';
import VerifyClient from './VerifyClient';

export default function VerifyPage() {
  return (
    <Suspense fallback={<div className="verify-shell"><div className="verify-card">Loading verification form...</div></div>}>
      <VerifyClient />
    </Suspense>
  );
}
