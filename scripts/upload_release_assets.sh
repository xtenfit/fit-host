#!/usr/bin/env bash
set -euo pipefail

RELEASE_ID="${1:-429794492}"
TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "${TOKEN}" && -f "website/.env.local" ]]; then
  TOKEN="$(grep -E '^GITHUB_TOKEN=' website/.env.local | cut -d= -f2)"
fi

if [[ -z "${TOKEN}" ]]; then
  echo "Error: GITHUB_TOKEN environment variable is required."
  exit 1
fi

BASE_UPLOAD="https://uploads.github.com/repos/xtenfit/fit-host/releases/${RELEASE_ID}/assets"

upload_asset() {
  local file="$1"
  local name="$2"
  local mime="$3"
  echo "Uploading ${name} (${file}) ..."
  curl -s -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: ${mime}" \
    --data-binary @"${file}" \
    "${BASE_UPLOAD}?name=${name}" | grep -E '"name"|"browser_download_url"|"size"' || true
  echo ""
}

upload_asset "website/public/downloads/FitHost-v1.3.0-arm64-v8a.apk" "FitHost-v1.3.0-arm64-v8a.apk" "application/vnd.android.package-archive"
upload_asset "website/public/downloads/FitHost-v1.3.0-arm64-v8a.apk.sha256" "FitHost-v1.3.0-arm64-v8a.apk.sha256" "text/plain"

upload_asset "website/public/downloads/FitHost-v1.3.0-armeabi-v7a.apk" "FitHost-v1.3.0-armeabi-v7a.apk" "application/vnd.android.package-archive"
upload_asset "website/public/downloads/FitHost-v1.3.0-armeabi-v7a.apk.sha256" "FitHost-v1.3.0-armeabi-v7a.apk.sha256" "text/plain"

upload_asset "website/public/downloads/FitHost-v1.3.0-x86_64.apk" "FitHost-v1.3.0-x86_64.apk" "application/vnd.android.package-archive"
upload_asset "website/public/downloads/FitHost-v1.3.0-x86_64.apk.sha256" "FitHost-v1.3.0-x86_64.apk.sha256" "text/plain"

upload_asset "FitHost-Android-v1.3.0.apk" "FitHost-Android-v1.3.0.apk" "application/vnd.android.package-archive"
upload_asset "FitHost-Android-v1.3.0.apk.sha256" "FitHost-Android-v1.3.0.apk.sha256" "text/plain"

echo "All release assets uploaded successfully!"
