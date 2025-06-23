#!/bin/sh
set -euo pipefail

# Just use the tool name — don't hardcode full path
KAFKA_CLI="kafka-console-producer.sh"

# Verify it's available
if ! command -v "$KAFKA_CLI" >/dev/null 2>&1; then
  echo "❌ $KAFKA_CLI not found in PATH"
  exit 1
fi

# Detect environment
VM_ID=$(hostname)
USER_ID="user_$VM_ID"
TOPIC="global.chat"
MESSAGE="Hello, I am $USER_ID, from $VM_ID!"

# Send message using kafka-console-producer
echo "$MESSAGE" | "$KAFKA_CLI" \
  --bootstrap-server kafka:9092 \
  --topic "$TOPIC" > /dev/null

echo "📨 Sent greeting: \"$MESSAGE\" to topic: $TOPIC"