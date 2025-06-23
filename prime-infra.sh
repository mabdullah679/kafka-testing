#!/bin/bash

set -euo pipefail

# Config
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$PROJECT_DIR/run-kafka-testing.sh"
ALIAS_NAME="prov-kafka-test-env"
ALIAS_COMMAND="alias $ALIAS_NAME='$SCRIPT_PATH'"
CLEAN_ALIAS_NAME="clean"
CLEAN_SCRIPT="$PROJECT_DIR/clean-project.sh"
CLEAN_COMMAND="alias $CLEAN_ALIAS_NAME='bash $CLEAN_SCRIPT'"

ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# Add alias only if it's not already present
add_alias_if_missing() {
  local rc_file="$1"
  [ -f "$rc_file" ] || touch "$rc_file"

  if ! grep -Fxq "$ALIAS_COMMAND" "$rc_file"; then
    echo "$ALIAS_COMMAND" >> "$rc_file"
    echo "✅ Alias added to $rc_file for $ALIAS_NAME"
  else
    echo "✅ Alias already present in $rc_file for $ALIAS_NAME"
  fi

  if ! grep -Fxq "$CLEAN_COMMAND" "$rc_file"; then
    echo "$CLEAN_COMMAND" >> "$rc_file"
    echo "✅ Alias added to $rc_file for $CLEAN_ALIAS_NAME"
  else
    echo "✅ Alias already present in $rc_file for $CLEAN_ALIAS_NAME"
  fi
}

echo "🔧 Setting up aliases for Kafka testing environment..."

# Ensure main script is executable
if [[ -f "$SCRIPT_PATH" ]]; then
  chmod +x "$SCRIPT_PATH" 2>/dev/null || echo "⚠️ Could not chmod $SCRIPT_PATH (already executable or permission issue)"
else
  echo "❌ $SCRIPT_PATH not found. Please check the path and try again."
  exit 1
fi

# Ensure clean script is executable
if [[ -f "$CLEAN_SCRIPT" ]]; then
  chmod +x "$CLEAN_SCRIPT" 2>/dev/null || echo "⚠️ Could not chmod $CLEAN_SCRIPT (already executable or permission issue)"
else
  echo "❌ $CLEAN_SCRIPT not found. Please create it before continuing."
  exit 1
fi

add_alias_if_missing "$ZSHRC"
add_alias_if_missing "$BASHRC"

echo "🎉 Alias setup complete."
echo "   ➜ Run: source ~/.zshrc OR source ~/.bashrc"
echo "   ➜ Then use: $ALIAS_NAME or $CLEAN_ALIAS_NAME"

# Prompt to run
read -rp "🤖 Do you want to run '$ALIAS_NAME' now? (y/n): " RUN_NOW
RUN_NOW=$(echo "$RUN_NOW" | tr '[:upper:]' '[:lower:]')

if [[ "$RUN_NOW" == "y" ]]; then
  echo -e "\n🚀 Running '$ALIAS_NAME'..."
  bash -c "$SCRIPT_PATH"
else
  echo "📝 You can run it later by typing: $ALIAS_NAME"
fi