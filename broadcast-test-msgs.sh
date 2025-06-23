#!/bin/bash
set -euo pipefail

# Auto-abort if vm1/vm2 containers are not available
if ! docker ps -a --format '{{.Names}}' | grep -Eq '^kafka-testing-vm[1-2]-app$'; then
  echo "❌ No target containers (vm1/vm2) found. Make sure the Kafka infra is running."
  exit 1
fi

echo "📜 Function: Sends greeting messages to global.chat topic using kafka-console-producer"
echo "------------------------------------------------------------"

# === Helpers ===

wait_for_running() {
  local cid="$1"
  local name="$2"
  local tries=20
  local delay=1
  for ((i=1; i<=tries; i++)); do
    status=$(docker inspect -f '{{.State.Running}}' "$cid" 2>/dev/null || echo "false")
    if [[ "$status" == "true" ]]; then return 0; fi
    sleep "$delay"
  done
  echo "❌ $name container failed to start after ${tries}s"
  return 1
}

find_script_path() {
  local cid="$1"
  docker exec "$cid" sh -c 'find / -type f -name "send-msg.sh" -executable 2>/dev/null | head -n 1'
}

# === Logic ===

found_any=false

for name in vm1-app vm2-app; do
  cid=$(docker ps -aqf "name=$name")
  if [ -z "$cid" ]; then
    echo "❌ No container found with name matching '$name'"
    continue
  fi

  # Ensure container is running
  if [[ "$(docker inspect -f '{{.State.Running}}' "$cid")" != "true" ]]; then
    echo "🔁 Starting container $name ($cid)..."
    docker start "$cid" >/dev/null
    wait_for_running "$cid" "$name" || continue
  fi

  # Locate the script dynamically
  script_path=$(find_script_path "$cid")
  if [[ -z "$script_path" ]]; then
    echo "❌ send-msg.sh not found or not executable in $name container"
    continue
  fi

  # Run it
  echo "📨 Sending message from container $cid ($name) via $script_path..."
  if docker exec -i "$cid" sh "$script_path"; then
    found_any=true
  else
    echo "⚠️ Failed to send from container ($name)"
  fi
done

echo "------------------------------------------------------------"

if [[ "$found_any" != "true" ]]; then
  echo "❌ No messages sent. Check if send-msg.sh exists and is executable inside containers."
  exit 1
else
  echo "✅ Finished sending messages from all applicable containers."
fi