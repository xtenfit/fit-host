/**
 * Fit Host Authentication & Redirection Utilities
 */

/**
 * Sanitizes the next redirect path to prevent open redirect vulnerabilities.
 * Ensures the target is a relative path starting with a single '/' and not protocol-relative ('//').
 */
export function sanitizeNextUrl(rawNext: string | null): string {
  if (!rawNext) return '/dashboard';
  if (rawNext.startsWith('/') && !rawNext.startsWith('//') && !rawNext.includes('\\')) {
    return rawNext;
  }
  return '/dashboard';
}
