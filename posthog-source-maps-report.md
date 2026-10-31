PostHog source map upload setup

⚠️ Needs your attention

No existing CI/CD configuration builds the Flutter app. Add POSTHOG_CLI_API_KEY, POSTHOG_CLI_PROJECT_ID, and POSTHOG_CLI_HOST to the secret/variable store used by the real production build environment.

The repository-wide flutter analyze still exits with one pre-existing lint notice in lib/core/services/exercise_media_service.dart:315; the changed PostHog Dart integration analyzes cleanly.

The iOS upload phase uses PostHog’s Flutter/CocoaPods script. This checkout currently has no ios/Podfile; ensure the production iOS environment generates or restores the CocoaPods integration so ${PODS_ROOT}/PostHog/build-tools/upload-symbols.sh exists.

What changed

android/settings.gradle.kts

android/app/build.gradle.kts

ios/Runner.xcodeproj/project.pbxproj

lib/core/services/analytics_service.dart

scripts/build_web_release.sh

.env

posthog-source-maps-report.md

The temporary Test PostHog Error Tracking button was added for the guided test and then reverted. No test affordance remains in the app.

Environment variables

The existing root .env now contains these variable names:

POSTHOG_CLI_API_KEY

POSTHOG_CLI_PROJECT_ID

POSTHOG_CLI_HOST

No secret values are included in this report.

Build, upload, and run commands

Web

Production build and upload:

bash scripts/build_web_release.sh
The helper runs these exact commands:

flutter build web --source-maps
posthog-cli --dotenv-file .env sourcemap process --directory build/web
Run the built artifact:

python3 -m http.server 8000 --directory build/web
Android

Production build and automatic mapping upload:

flutter build apk --release
The com.posthog.android Gradle plugin hooks the minified release build, so there is no separate manual upload command. It reads the POSTHOG_CLI_* variables from the root .env locally or from the process environment in CI.

Run:

flutter run --release
iOS

Production build and automatic dSYM upload:

flutter build ipa
The final Runner build phase invokes:

POSTHOG_INCLUDE_SOURCE=1 POSTHOG_CLI_DOTENV_FILE="${SRCROOT}/../.env" "${PODS_ROOT}/PostHog/build-tools/upload-symbols.sh"
Run:

flutter run --release
CI/CD follow-up

No checked-in Dockerfile or CI workflow runs a Flutter production build. The only GitHub Actions workflow revalidates website release cache and does not build this app, so it was left unchanged.

Wherever the production Flutter builds actually run, create or expose these variables at the build step:

POSTHOG_CLI_API_KEY — secret

POSTHOG_CLI_PROJECT_ID — variable or secret

POSTHOG_CLI_HOST — variable or secret

Do not write them to a CI-generated .env file. Pass them as environment variables, and thread them through any Docker, composite-action, or SSH boundary if one exists outside this repository.

Verification

Run the appropriate production build command above. Uploads occur during that build.

Open the PostHog Symbol sets page.

Confirm a fresh source map, Android mapping, or iOS dSYM symbol set appears for the build.

Capture an exception from that exact built artifact and confirm Error Tracking resolves frames to real source files and line numbers.

Validation performed

Confirmed all three POSTHOG_CLI_* keys are present in .env without reading their values.

Confirmed the temporary test affordance was fully removed.

flutter analyze lib/core/services/analytics_service.dart passes with no issues.

Repository-wide flutter analyze reaches completion but exits for one unrelated existing lint notice in lib/core/services/exercise_media_service.dart:315.
