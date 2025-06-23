#!/bin/bash

# 💡 Parse arguments
OUTPUT_MODE="${1:-short}"     # short | full
LOG_MODE="${2:-logs}"         # logs | no-logs

# 📁 Ensure logs dir exists
mkdir -p logs

# 📄 Create dynamic log filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/clean-rebuild-$TIMESTAMP.log"
TEMP_LOG=$(mktemp)

# 🚀 Run the actual script, capturing all output
bash ./clean-rebuild.sh > "$TEMP_LOG" 2>&1
SCRIPT_EXIT_CODE=$?

# ✏️ Write to log file if requested
if [[ "$LOG_MODE" == "logs" ]]; then
    cp "$TEMP_LOG" "$LOG_FILE"
    echo "📂 Log saved to $LOG_FILE"
fi

# 📺 Output to terminal
if [[ "$OUTPUT_MODE" == "full" ]]; then
    cat "$TEMP_LOG"
else
    echo "📦 docker-compose status summary:"
    grep -E "docker|mvn" "$TEMP_LOG" | grep -Ei "error|fail|success|completed|exit|starting|stopping" || echo "(No status output)"
fi

echo "✅ Script finished with exit code: $SCRIPT_EXIT_CODE"

# 🧹 Cleanup temp log
rm "$TEMP_LOG"