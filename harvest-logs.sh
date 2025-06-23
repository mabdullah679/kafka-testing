#!/bin/bash
set -euo pipefail

SHOW_HELP=0
COPY_TO_CLIPBOARD=0

for arg in "$@"; do
  case "$arg" in
    --copy) COPY_TO_CLIPBOARD=1 ;;
    --help) SHOW_HELP=1 ;;
  esac
done

if [[ $SHOW_HELP -eq 1 ]]; then
  cat <<EOF
🆘 Usage: ./harvest-logs.sh [--copy] [--help]

  --copy   Copy log summary to clipboard
  --help   Show this help message and exit
EOF
  exit 0
fi

echo "📦 Categorizing logs from vm1, vm2, and vm3..."

output=""

extract_logs() {
  local container=$1
  local label=$2
  local logs
  logs=$(docker logs "$container" 2>&1 || echo "N/A")

  if [[ -z "$logs" || "$logs" == "N/A" || "$logs" =~ "No such container" ]]; then
    output+="❌ $container has no logs or is unavailable.\n"
    return
  fi

  output+="\n🔍 Logs from $container ($label):\n"

  if echo "$logs" | grep -qiE 'ready|active|success|started'; then
    output+="🟢 [4b] Successful deployment:\n"
    output+="$(echo "$logs" | grep -Ei 'ready|active|success|started')\n"
  fi

  if echo "$logs" | grep -qiE 'warn|debug|info'; then
    output+="🟡 [4c] Buggy but live:\n"
    output+="$(echo "$logs" | grep -Ei 'warn|debug')\n"
  fi

  if echo "$logs" | grep -qiE 'error|fail|exception|unhealthy'; then
    output+="🔴 [4d] Unhealthy logs:\n"
    output+="$(echo "$logs" | grep -Ei 'error|fail|exception|unhealthy')\n"
  fi
}

extract_transmissions() {
  echo "📡 Extracting audit messages from vm3-app..."
  transmission_logs=$(docker exec kafka-testing-vm3-app sh -c "find /app/audit -type f -name 'transmission.log' -exec cat {} +" 2>/dev/null || echo "")

  if [[ -z "$transmission_logs" ]]; then
    output+="\n❌ No transmission logs found in vm3.\n"
    return
  fi

  output+="\n📜 [Audit] Messages recorded by vm3:\n"
  output+="$transmission_logs\n"
}

extract_logs kafka-testing-vm1-app "vm1"
extract_logs kafka-testing-vm2-app "vm2"
extract_logs kafka-testing-vm3-app "vm3"
extract_transmissions

echo -e "$output"

if [[ $COPY_TO_CLIPBOARD -eq 1 ]]; then
  echo -e "$output" | pbcopy
  echo "📋 Log summary copied to clipboard."
fi