#!/usr/bin/env bash
# Non-interactive end-to-end check of the chat flow. Assumes `docker compose up -d` is already running.
# vm3 (broker handler) creates the topic, vm2 listens, vm1 sends a unique marker; vm2 and vm3's audit log must both see it.
# Exits 0 only if the marker arrives at vm2 AND is written to vm3's audit log.
set -euo pipefail

OUT="$(mktemp -d)"
MARKER="e2e-$(date +%s)-$RANDOM"
trap 'kill $(jobs -p) 2>/dev/null || true; rm -rf "$OUT"' EXIT

wait_for() { # file pattern seconds
  for _ in $(seq 1 "$3"); do grep -q "$2" "$1" 2>/dev/null && return 0; sleep 1; done
  echo "TIMEOUT waiting for '$2' in $1"; tail -20 "$1" 2>/dev/null || true; return 1
}

# vm3 asks "Create it now? [Y/n]" only when the topic is missing; answer it once the prompt shows up.
( for _ in $(seq 1 30); do grep -q "Create it now\|already exists" "$OUT/vm3.out" 2>/dev/null && break; sleep 1; done
  grep -q "Create it now" "$OUT/vm3.out" && echo Y
  sleep 150 ) | docker exec -i vm3-app java -jar app.jar --from=beginning >"$OUT/vm3.out" 2>&1 &
wait_for "$OUT/vm3.out" "Broker ready" 90

(sleep 120) | docker exec -i vm2-app java -jar app.jar --from=beginning >"$OUT/vm2.out" 2>&1 &
wait_for "$OUT/vm2.out" "Connected to Kafka chat" 60

(sleep 3; echo "$MARKER"; sleep 3; echo exit) | docker exec -i vm1-app java -jar app.jar >"$OUT/vm1.out" 2>&1
wait_for "$OUT/vm2.out" "$MARKER" 90
echo "PASS: vm2 received $MARKER"
wait_for "$OUT/vm3.out" "$MARKER" 30
echo "PASS: vm3 audited $MARKER"
docker exec vm3-app sh -c "grep -l '$MARKER' /app/logs/audit-*.log" >/dev/null
echo "PASS: marker present in vm3 audit log file"
