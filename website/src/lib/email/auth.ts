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
  if (configuredAdminEmails.length > 0) {
    return configuredAdminEmails.includes(normalized);
  }

  // Built-in verified domain administrators
  if (normalized.endsWith('@amitrana.tech') || normalized.endsWith('@amitran.tech')) {
    return true;
  }

  // In development environment, allow local test session
  if (process.env.NODE_ENV === 'development') {
    return true;
  }

  return false;
}

/**
 * Server-side authorization check for administrative email routes and actions.
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
      // In development mode, allow seamless local inspection if enabled
      if (process.env.NODE_ENV === 'development') {
        return {
          authorized: true,
          userEmail: 'dev-admin@fithost.local',
        };
      }

      return {
        authorized: false,
        reason: 'Unauthenticated: Sign in to an authorized administrator account to access Email Studio.',
      };
    }

    // Check Supabase custom app_metadata role
    const appRole = user.app_metadata?.role;
    if (appRole === 'admin' || appRole === 'superadmin') {
      return { authorized: true, userEmail: user.email };
    }

    // Check email whitelist
    if (isAuthorizedAdminEmail(user.email)) {
      return { authorized: true, userEmail: user.email };
    }

    return {
      authorized: false,
      userEmail: user.email,
      reason: `User (${user.email}) does not possess administrator privileges for Email Studio.`,
    };
  } catch (err: unknown) {
    if (process.env.NODE_ENV === 'development') {
      return { authorized: true, userEmail: 'dev-admin@fithost.local' };
    }
    return {
      authorized: false,
      reason: err instanceof Error ? err.message : 'Authorization verification error',
    };
  }
}
