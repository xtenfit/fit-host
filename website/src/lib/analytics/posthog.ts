import posthog from "posthog-js";

/**
 * Sensitive parameter blacklist to strictly prevent PII, passwords,
 * tokens, or private user details from reaching PostHog.
 */
const SENSITIVE_KEYS = new Set([
  "email",
  "password",
  "token",
  "secret",
  "auth",
  "authorization",
  "apikey",
  "api_key",
  "body_weight",
  "weight",
  "nutrition",
  "meal",
  "note",
  "notes",
  "address",
  "phone",
]);

/**
 * Filter properties object to strip sensitive information.
 */
export function sanitizeAnalyticsProperties(
  props?: Record<string, unknown>
): Record<string, unknown> {
  if (!props) return {};
  const cleaned: Record<string, unknown> = {};

  for (const [key, value] of Object.entries(props)) {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_KEYS.has(lowerKey)) continue;

    if (typeof value === "string") {
      // Redact potential emails or tokens
      let val = value.replace(
        /[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/g,
        "[REDACTED_EMAIL]"
      );
      val = val.replace(/Bearer\s+[A-Za-z0-9\-_.]+/gi, "Bearer [REDACTED]");
      val = val.replace(/sb_[A-Za-z0-9_\-]+/gi, "[REDACTED_KEY]");
      cleaned[key] = val;
    } else if (
      typeof value === "number" ||
      typeof value === "boolean" ||
      value === null
    ) {
      cleaned[key] = value;
    } else if (Array.isArray(value)) {
      cleaned[key] = value.length; // Count only
    } else if (typeof value === "object") {
      cleaned[key] = sanitizeAnalyticsProperties(value as Record<string, unknown>);
    }
  }

  return cleaned;
}

let isInitialized = false;

/**
 * Initialize PostHog client safely with privacy guards.
 */
export function initPostHog(): void {
  if (typeof window === "undefined" || isInitialized) return;

  const apiKey = process.env.NEXT_PUBLIC_POSTHOG_KEY;
  const apiHost =
    process.env.NEXT_PUBLIC_POSTHOG_HOST || "https://us.i.posthog.com";

  if (!apiKey) {
    if (process.env.NODE_ENV === "development") {
      console.info(
        "ℹ️ [PostHog] NEXT_PUBLIC_POSTHOG_KEY not set. Analytics operating in safe mock mode."
      );
    }
    isInitialized = true;
    return;
  }

  try {
    posthog.init(apiKey, {
      api_host: apiHost,
      person_profiles: "identified_only",
      autocapture: false,
      disable_session_recording: true,
      capture_pageview: true,
      capture_pageleave: true,
      enable_recording_console_log: false,
      loaded: (ph) => {
        if (process.env.NODE_ENV === "development") {
          ph.debug(false);
        }
      },
    });

    // Unhandled exception listener
    window.addEventListener("error", (event) => {
      posthog.captureException(event.error || new Error(event.message));
    });

    // Unhandled promise rejection listener
    window.addEventListener("unhandledrejection", (event) => {
      posthog.captureException(
        event.reason instanceof Error
          ? event.reason
          : new Error(String(event.reason))
      );
    });

    isInitialized = true;
  } catch (err) {
    console.warn("⚠️ [PostHog] Initialization fallback error:", err);
    isInitialized = true;
  }
}

/**
 * Track an analytics event safely.
 */
export function trackEvent(
  eventName: string,
  properties?: Record<string, unknown>
): void {
  if (typeof window === "undefined") return;

  const sanitized = sanitizeAnalyticsProperties(properties);
  sanitized.environment = process.env.NODE_ENV || "development";
  sanitized.timestamp = new Date().toISOString();

  try {
    if (posthog.__loaded) {
      posthog.capture(eventName, sanitized);
    } else if (process.env.NODE_ENV === "development") {
      console.debug(`[Analytics Mock] ${eventName}`, sanitized);
    }
  } catch (err) {
    console.warn("[Analytics] Track error:", err);
  }
}

/**
 * Record an application exception to PostHog error tracking.
 */
export function trackException(
  error: unknown,
  context?: Record<string, unknown>
): void {
  if (typeof window === "undefined") return;

  const sanitizedContext = sanitizeAnalyticsProperties(context);
  sanitizedContext.environment = process.env.NODE_ENV || "development";

  try {
    const errObj =
      error instanceof Error ? error : new Error(String(error));
    if (posthog.__loaded) {
      posthog.captureException(errObj, sanitizedContext);
    } else {
      console.error("[PostHog Error Fallback]", errObj, sanitizedContext);
    }
  } catch (err) {
    console.warn("[Analytics] CaptureException error:", err);
  }
}

/**
 * Identify an authenticated user by anonymous ID (UUID only).
 */
export function identifyUser(
  userId: string,
  properties?: Record<string, unknown>
): void {
  if (typeof window === "undefined" || !userId || userId === "guest") return;

  const safeId = userId.includes("@") ? "anonymized_user" : userId;
  const sanitized = sanitizeAnalyticsProperties(properties);

  try {
    if (posthog.__loaded) {
      posthog.identify(safeId, sanitized);
    }
  } catch (err) {
    console.warn("[Analytics] Identify error:", err);
  }
}

/**
 * Reset user session on logout.
 */
export function resetUserSession(): void {
  if (typeof window === "undefined") return;
  try {
    if (posthog.__loaded) {
      posthog.reset();
    }
  } catch (err) {
    console.warn("[Analytics] Reset error:", err);
  }
}

