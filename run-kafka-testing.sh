#!/bin/bash
set -euo pipefail

# Prep: resolve directory and clean project metadata
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/clean-project.sh"

cd "$SCRIPT_DIR"

# Deploy logic
if docker ps --format '{{.Names}}' | grep -q kafka-testing-vm3-app; then
  echo "📈 Existing infrastructure detected."
  read -rp "❓ Do you want to purge and redeploy everything? (y/n): " resp
  if [[ "$resp" == "y" ]]; then
    echo "♻️ Rebuilding and redeploying..."
    echo "🧹 Cleaning up persistent log files..."
    rm -f logs/*.log || true

    docker compose down -v --remove-orphans
    docker compose build
    docker compose up -d
  fi
else
  echo "🚀 First-time setup. Deploying..."
  docker compose build
  docker compose up -d
fi

# Wait for vm3-app to report readiness
echo "⏳ Waiting for vm3-app to report readiness..."
MAX_TRIES=30
WAIT_SECS=2
READY_MSG="Kafka broker handler is active."

for ((i = 1; i <= MAX_TRIES; i++)); do
  if docker logs kafka-testing-vm3-app 2>&1 | grep -q "$READY_MSG"; then
    echo "✅ vm3-app is healthy and broker handler is ready."
    break
  fi
  sleep "$WAIT_SECS"
done

if ! docker logs kafka-testing-vm3-app 2>&1 | grep -q "$READY_MSG"; then
  echo "❌ Timed out waiting for vm3-app to be ready. Check logs manually."
  exit 1
fi

# Prompt to send messages
read -rp $'📨 Restart vm1/vm2 and send test messages?\n(y/n): ' send_msgs
if [[ "$send_msgs" == "y" ]]; then
  for vm in vm1-app vm2-app; do
    echo "🔁 Restarting kafka-testing-$vm..."
    docker restart "kafka-testing-$vm" >/dev/null
  done

  echo "💬 Broadcasting messages from vm1 and vm2 via broadcast-test-msgs.sh..."
  echo "📜 Function: Sends greeting messages to global.chat topic using kafka-console-producer"
  echo "------------------------------------------------------------"
  bash "$SCRIPT_DIR/broadcast-test-msgs.sh"
  echo "------------------------------------------------------------"
fi

# Prompt to harvest logs
read -rp $'📦 Would you like to harvest logs?\n(y/n or y --copy / --help): ' harvest_input
harvest_flag=$(echo "$harvest_input" | awk '{print $1}')
harvest_option=$(echo "$harvest_input" | awk '{print $2}')

case "$harvest_flag" in
  y)
    echo "📤 Harvesting logs..."
    if [[ "$harvest_option" == "--copy" ]]; then
      bash "$SCRIPT_DIR/harvest-logs.sh" --copy
    else
      bash "$SCRIPT_DIR/harvest-logs.sh"
    fi
    ;;
  --help)
    echo -e "\n🆘 Log Harvesting Help:\n  y          → Harvest logs\n  y --copy   → Harvest and copy logs to clipboard\n  --help     → Show this help message\n"
    ;;
  *)
    echo "❌ Invalid input. Use 'y', 'y --copy', or '--help'."
    ;;
esac

exit 0