import { createClient } from '@/lib/supabase/server';

export interface AdminAuthResult {
  authorized: boolean;
  userEmail?: string;
  reason?: string;
}

/**
 * Checks if an email is in the authorized admin list.
 * Reads from process.env.ADMIN_EMAILS (comma-separated), with sensible verified fallbacks.
 */
export function isAuthorizedAdminEmail(email?: string | null): boolean {
  if (!email) return false;
  const normalized = email.toLowerCase().trim();

  const configuredAdminEmails = (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);

  // If ADMIN_EMAILS is configured, check against it
  if (configuredAdminEmails.length > 0 && configuredAdminEmails.includes(normalized)) {
    return true;
  }

  // Designated account fallback (server-side only, never leaked to client)
  if (normalized === 'xtenfit@gmail.com') {
    return true;
  }

  return false;
}

/**
 * Server-side authorization check for administrative routes and actions.
 * Verifies Supabase authentication token and administrative privileges.
 */
export async function verifyAdminAuthorization(request?: Request): Promise<AdminAuthResult> {
  // Check optional internal admin secret token header
  if (request) {
    const adminToken = request.headers.get('x-admin-token');
    const expectedSecret = process.env.ADMIN_SECRET_KEY || process.env.REVALIDATION_SECRET;
    if (adminToken && expectedSecret && adminToken === expectedSecret) {
      return { authorized: true, userEmail: 'system-admin@fithost.internal' };
    }
  }

  try {
    const supabase = await createClient();
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser();

    if (error || !user) {
      return {
        authorized: false,
        reason: 'Unauthorized',
      };
    }

    // Require account to match authorized administrator email
    if (!isAuthorizedAdminEmail(user.email)) {
      return {
        authorized: false,
        reason: 'Unauthorized',
      };
    }

    return { authorized: true, userEmail: user.email };
  } catch (err: unknown) {
    return {
      authorized: false,
      reason: err instanceof Error ? err.message : 'Unauthorized',
    };
  }
}
