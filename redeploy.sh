#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT" || exit 1

TEMP_LOG="$PROJECT_ROOT/redeploy_temp.log"
: > "$TEMP_LOG"  # Clear the log at the very start

sleep_and_echo() {
  echo -e "$1"
  sleep 1
}

log_and_fail() {
  echo "❌ $1"
  echo "📄 See full logs here: $TEMP_LOG"
  exit 1
}

sleep_and_echo "📁 Starting redeployment from: $PROJECT_ROOT"

### 1. Docker daemon check
sleep_and_echo "🔍 Checking if Docker is running..."
docker info > /dev/null 2>&1 || log_and_fail "Docker is not running. Start Docker Desktop and rerun this script."
echo "✅ Docker is up."

### 2. Clean macOS metadata (._* files)
sleep_and_echo "🧹 Scanning for macOS metadata files (._*)..."
if find . -type f -name '._*' | grep -q .; then
  find . -type f -name '._*' -delete
  echo "✅ Cleaned macOS metadata files."
else
  echo "✅ No macOS metadata files found."
fi

### 3. Stop and clean up containers
sleep_and_echo "♻️  Tearing down existing containers (if any)..."
docker compose down --volumes --remove-orphans > /dev/null 2>&1 || true
echo "✅ Cleanup complete."

### 4. Build Docker images
sleep_and_echo "🔨 Building Docker images..."
docker compose build --no-cache > "$TEMP_LOG" 2>&1 || log_and_fail "Build failed. Check Dockerfile paths, permissions, or missing dependencies."

echo "🔎 Build output summary:"
grep "Built" "$TEMP_LOG" | sed 's/^/ ✔ /' || echo "(no build summary found)"
echo "✅ Build complete."

### 5. Start containers
sleep_and_echo "🚀 Starting containers..."
docker compose up -d >> "$TEMP_LOG" 2>&1 || log_and_fail "Container startup failed. See logs with: docker compose logs --tail=50"

echo "🔎 Container status:"
docker compose ps --status=running || echo "⚠️ Some services may not have started properly."
echo "✅ Containers are running."

sleep_and_echo "🎉 Kafka testing stack is up and ready to use."

# Optional: Delete log if build and startup succeed fully
rm -f "$TEMP_LOG"