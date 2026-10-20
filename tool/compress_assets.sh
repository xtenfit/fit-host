#!/bin/bash
# tool/compress_assets.sh - Lossless / Near-Lossless Asset Compression Pipeline
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$DIR/.." && pwd)"

echo "Running asset compression script..."
node "$PROJECT_DIR/tool/compress_assets.js"
