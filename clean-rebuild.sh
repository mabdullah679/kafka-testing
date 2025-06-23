#!/bin/bash
set -euo pipefail

echo "🧹 Cleaning up Docker environment and macOS metadata..."
docker compose down -v --remove-orphans

echo "🗑️ Removing macOS metadata files (._*)..."
find . -name '._*' -delete

echo "🔨 Rebuilding Docker containers from scratch..."
docker compose build --no-cache

echo "🚀 Bringing up Kafka test infrastructure..."
docker compose up -d

echo "✅ Done. Infra is rebuilding cleanly and starting up."