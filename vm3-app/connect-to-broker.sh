#!/bin/sh
set -euo pipefail

# Healthcheck hook
if [[ "${1:-}" == "--healthcheck" ]]; then
  echo "Kafka broker handler ready"
  exit 0
fi

# Audit root setup (ensure ./audit exists)
AUDIT_ROOT="./audit"
mkdir -p "$AUDIT_ROOT"

# User-specific session directory
USER_ID="user_$(date +%s)"
AUDIT_DIR="$AUDIT_ROOT/$USER_ID"
mkdir -p "$AUDIT_DIR"

echo "📡 Kafka broker handler is active."
echo "📂 Session logs will be stored in: $AUDIT_DIR"

# Keep process alive
tail -f /dev/null