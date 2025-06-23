#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🧼 Cleaning project metadata and artifacts..."

# Delete AppleDouble files (macOS metadata)
find "$PROJECT_DIR" -name '._*' -delete

# Optional: Clean up logs and Docker state
rm -rf "$PROJECT_DIR/logs"/*.log || true
docker compose down -v --remove-orphans || true

# Extra cleanup just in case
rm -f "$PROJECT_DIR"/*/.dockerignore~* || true

echo "✅ Project cleaned successfully."