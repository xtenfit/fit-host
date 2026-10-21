import { getSupabaseClient } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export default async function AdminPage() {
  try {
    const supabase = getSupabaseClient();
    const { data: users, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      return (
        <main className="verify-shell">
          <section className="verify-card">
            <h1>Admin access</h1>
            <p>Unable to load verified user data.</p>
          </section>
        </main>
      );
    }

    return (
      <main className="verify-shell">
        <section className="verify-card" style={{ width: 'min(960px, 100%)' }}>
          <h1>Verified users</h1>
          <p>Manage signups and monitor email verification status.</p>

          <div style={{ overflowX: 'auto', marginTop: 20 }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ textAlign: 'left', borderBottom: '1px solid #e5e7eb' }}>
                  <th style={{ padding: '12px 10px' }}>Name</th>
                  <th style={{ padding: '12px 10px' }}>Email</th>
                  <th style={{ padding: '12px 10px' }}>Company</th>
                  <th style={{ padding: '12px 10px' }}>Status</th>
                  <th style={{ padding: '12px 10px' }}>Created</th>
                </tr>
              </thead>
              <tbody>
                {users?.map((user) => (
                  <tr key={user.id} style={{ borderBottom: '1px solid #f3f4f6' }}>
                    <td style={{ padding: '12px 10px' }}>{user.name}</td>
                    <td style={{ padding: '12px 10px' }}>{user.email}</td>
                    <td style={{ padding: '12px 10px' }}>{user.company || '—'}</td>
                    <td style={{ padding: '12px 10px' }}>
                      {user.is_verified ? 'Verified' : 'Pending'}
                    </td>
                    <td style={{ padding: '12px 10px' }}>
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <a href="/" className="verify-link">← Back to home</a>
        </section>
      </main>
    );
  } catch (error) {
    return (
      <main className="verify-shell">
        <section className="verify-card">
          <h1>Admin access</h1>
          <p>Environment is not configured yet. Add Supabase values in Vercel to enable this dashboard.</p>
        </section>
      </main>
    );
  }
}
