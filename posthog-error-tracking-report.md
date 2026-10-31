# PostHog error tracking

> ⚠️ **Needs your attention**
> - Run production builds from a real repository checkout with `.git` intact and provide `POSTHOG_CLI_API_KEY`, `POSTHOG_CLI_PROJECT_ID`, and `POSTHOG_CLI_HOST` on every build machine; if builds move to GitHub Actions, add them to Settings → Secrets and variables → Actions and expose them only to the release build step.
> - Install the global CLI on machines that run the web release wrapper: `npm install -g @posthog/cli@latest`.
> - Use `scripts/build_web_release.sh` for web releases instead of bare `flutter build web`, and keep the runtime `.env` values `POSTHOG_API_KEY` or `POSTHOG_PROJECT_TOKEN` plus `POSTHOG_HOST` available to the packaged app.

## What error tracking does now

Uncaught Flutter framework errors, Dart runtime errors, main-isolate errors, and supported native crashes are captured automatically by the initialized PostHog Flutter SDK. The centralized configuration is in `lib/core/services/analytics_service.dart`; existing Crashlytics handlers in `lib/main.dart` were preserved. The SDK was already installed and initialized before this work, and it now has all four Flutter error-capture options enabled.

## Source maps and production builds

Source-map upload is wired in `scripts/build_web_release.sh`. The production web command is:

```sh
scripts/build_web_release.sh
```

It runs `flutter build web --source-maps`, then processes `build/web` with `posthog-cli --dotenv-file .env sourcemap process --directory build/web` when the upload credentials are available. Every web release built through that wrapper is set up to upload source maps. Android and iOS already contain native symbol-upload wiring: Android reads the `POSTHOG_CLI_*` variables from the Flutter-root `.env`, and iOS points its upload phase at that file.

The files changed for the upload pipeline are:

- `scripts/build_web_release.sh`
- `.env.example`
- `.env`

The upload variables are `POSTHOG_CLI_API_KEY`, `POSTHOG_CLI_PROJECT_ID`, and `POSTHOG_CLI_HOST`. The credentials are present in the root `.env`; values are not reproduced here.

## Verification

The production compiler command `flutter build web --source-maps` passed and produced `build/web/main.dart.js` and `build/web/main.dart.js.map`. The separate `posthog-cli` upload command and wrapper were not executed during verification, so no release name or uploaded-file count is available yet. The first upload will occur when the release wrapper is run with the configured variables. Android verification remains blocked by the pre-existing missing `dev.flutter.plugins.integration_test.IntegrationTestPlugin`; iOS reports that the application is not configured for iOS. Neither failure was caused by PostHog wiring.

The checked-in GitHub Actions workflow does not build, package, deploy, or start the Flutter app, so no CI file was changed and no deploy path could be wired. The documented production APK path is a manual `flutter build apk --release` from the repository checkout. If that process later moves to CI, expose the three exact `POSTHOG_CLI_*` names on the Flutter release build step; preserve the repository checkout so release identity can be derived. For web deployments outside this repository, invoke the wrapper above.

## How to verify in PostHog

Trigger an error and inspect [Error Tracking](https://us.posthog.com/project/689658/error_tracking). Uploaded symbol sets appear at [Error Tracking configuration](https://us.posthog.com/project/689658/error_tracking/configuration). After running a production web release through the wrapper, confirm that its symbol set appears in the configuration page and that captured stack traces resolve to source locations.
