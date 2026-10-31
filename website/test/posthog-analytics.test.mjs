import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const websiteRoot = path.resolve(__dirname, "..");

test("Fit Host PostHog Analytics & Web Error Tracking Verification", async (t) => {
  const posthogLibPath = path.join(websiteRoot, "src/lib/analytics/posthog.ts");
  const providerPath = path.join(
    websiteRoot,
    "src/components/providers/PostHogProvider.tsx"
  );
  const errorBoundaryPath = path.join(websiteRoot, "src/app/error.tsx");
  const globalErrorPath = path.join(websiteRoot, "src/app/global-error.tsx");

  await t.test("Required PostHog analytics files exist", () => {
    assert.ok(fs.existsSync(posthogLibPath), "posthog.ts must exist");
    assert.ok(fs.existsSync(providerPath), "PostHogProvider.tsx must exist");
    assert.ok(fs.existsSync(errorBoundaryPath), "error.tsx must exist");
    assert.ok(fs.existsSync(globalErrorPath), "global-error.tsx must exist");
  });

  await t.test("Property sanitizer strips sensitive fields", async () => {
    // Dynamic import the compiled or raw module
    const { sanitizeAnalyticsProperties } = await import(
      "../src/lib/analytics/posthog.ts"
    );

    const sensitivePayload = {
      action: "view_screen",
      email: "athlete@example.com",
      password: "SuperSecretPassword123",
      token: "jwt.fake.token",
      body_weight: 75.5,
      weight: 165,
      nutrition: { calories: 2500 },
      meal: "Oatmeal with protein powder",
      notes: "Feeling fatigued in lower back",
      address: "123 Gym St",
      phone: "+1234567890",
      screen: "workout_summary",
      duration_seconds: 1800,
      description: "Contacted athlete at athlete@example.com with Bearer eyJhbGciOi...",
      exercise_ids: ["ex1", "ex2", "ex3"],
    };

    const sanitized = sanitizeAnalyticsProperties(sensitivePayload);

    // Blocked keys should be completely omitted
    assert.strictEqual(sanitized.email, undefined);
    assert.strictEqual(sanitized.password, undefined);
    assert.strictEqual(sanitized.token, undefined);
    assert.strictEqual(sanitized.body_weight, undefined);
    assert.strictEqual(sanitized.weight, undefined);
    assert.strictEqual(sanitized.nutrition, undefined);
    assert.strictEqual(sanitized.meal, undefined);
    assert.strictEqual(sanitized.notes, undefined);
    assert.strictEqual(sanitized.address, undefined);
    assert.strictEqual(sanitized.phone, undefined);

    // Allowed non-sensitive metadata retained
    assert.strictEqual(sanitized.action, "view_screen");
    assert.strictEqual(sanitized.screen, "workout_summary");
    assert.strictEqual(sanitized.duration_seconds, 1800);

    // Arrays converted to length count
    assert.strictEqual(sanitized.exercise_ids, 3);

    // Strings with embedded emails and tokens are redacted
    assert.ok(!sanitized.description.includes("athlete@example.com"));
    assert.ok(sanitized.description.includes("[REDACTED_EMAIL]"));
    assert.ok(!sanitized.description.includes("eyJhbGciOi"));
    assert.ok(sanitized.description.includes("[REDACTED]"));
  });

  await t.test("Provider enforces privacy configuration rules", () => {
    const posthogContent = fs.readFileSync(posthogLibPath, "utf-8");

    // Must disable session recording by default
    assert.ok(
      posthogContent.includes("disable_session_recording: true"),
      "Must disable session recording by default"
    );

    // Must disable aggressive autocapture
    assert.ok(
      posthogContent.includes("autocapture: false"),
      "Must disable autocapture to prevent sensitive input logging"
    );

    // Must restrict person profiles to identified users only
    assert.ok(
      posthogContent.includes("person_profiles: \"identified_only\""),
      "Must set person_profiles to identified_only"
    );
  });

  await t.test("Client Error boundaries capture exceptions without crashing", () => {
    const errorContent = fs.readFileSync(errorBoundaryPath, "utf-8");
    assert.ok(
      errorContent.includes("trackException(error"),
      "error.tsx must report exceptions to PostHog error tracking"
    );

    const globalErrorContent = fs.readFileSync(globalErrorPath, "utf-8");
    assert.ok(
      globalErrorContent.includes("trackException(error"),
      "global-error.tsx must report fatal exceptions to PostHog error tracking"
    );
  });
});

