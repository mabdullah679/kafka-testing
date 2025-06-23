#!/bin/sh
set -euo pipefail

echo -e "\n💬 Kafka Messaging Interface"
echo "Type your message and press Enter."
echo "To exit, type 'exit', '/exit', or just press Ctrl+C."

USER_ID="user_$(hostname)"
LOG_DIR="./audit/$USER_ID"
LOG_FILE="$LOG_DIR/session_$(date +%s).log"
mkdir -p "$LOG_DIR"

while true; do
  read -rp "📝 Message > " input || break
  input=$(echo "$input" | xargs) # Trim whitespace
  case "$input" in
    exit|/exit)
      echo "👋 Exiting chat."
      break
      ;;
    *)
      echo "$(date): $USER_ID said: $input" | tee -a "$LOG_FILE"
      ;;
  esac
done