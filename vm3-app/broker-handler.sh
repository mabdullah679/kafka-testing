#!/bin/sh
set -euo pipefail

DEFAULT_TOPIC="global.chat"
KAFKA_HOST="kafka"
KAFKA_PORT="9092"

# Healthcheck hook
if [[ "${1:-}" == "--healthcheck" ]]; then
  echo "Kafka broker handler ready"
  exit 0
fi

AUDIT_ROOT="./audit"
USER_ID="user_$(date +%s)"
SESSION_ID="session_$(date +%s)"
AUDIT_DIR="$AUDIT_ROOT/$USER_ID/$SESSION_ID"
mkdir -p "$AUDIT_DIR"

echo "📡 Kafka broker handler is active."
echo "📂 Session logs will be stored in: $AUDIT_DIR"
echo "🧵 Ensuring Kafka topic '$DEFAULT_TOPIC' exists..."

kafka-topics --bootstrap-server "$KAFKA_HOST:$KAFKA_PORT" \
  --create --if-not-exists \
  --topic "$DEFAULT_TOPIC" \
  --partitions 1 \
  --replication-factor 1 || true

# Start consumer with live logging
SESSION_LOG="$AUDIT_DIR/transmission.log"
echo "🛸 Subscribed to '$DEFAULT_TOPIC'. Logging to $SESSION_LOG..."

kafka-console-consumer \
  --bootstrap-server "$KAFKA_HOST:$KAFKA_PORT" \
  --topic "$DEFAULT_TOPIC" \
  --from-beginning \
  | tee -a "$SESSION_LOG"