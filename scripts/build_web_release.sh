#!/usr/bin/env bash
set -euo pipefail

flutter build web --source-maps

has_env_key() {
  [[ -f .env ]] && grep -Eq "^${1}=.+" .env
}

if { [[ -n "${POSTHOG_CLI_API_KEY:-}" ]] || has_env_key POSTHOG_CLI_API_KEY; } &&
  { [[ -n "${POSTHOG_CLI_PROJECT_ID:-}" ]] || has_env_key POSTHOG_CLI_PROJECT_ID; }; then
  posthog-cli --dotenv-file .env sourcemap process --directory build/web
else
  echo "Skipping PostHog source map upload: POSTHOG_CLI_API_KEY and POSTHOG_CLI_PROJECT_ID are not configured."
fi
