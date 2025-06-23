#!/bin/bash

set -euo pipefail

# Config
PROJECT_DIR="/Volumes/DevXLab/Dev/kafka-testing"
SCRIPT_PATH="$PROJECT_DIR/run-kafka-testing.sh"
ALIAS_NAME="prov-kafka-test-env"
ALIAS_COMMAND="alias $ALIAS_NAME='$SCRIPT_PATH'"
CLEAN_ALIAS_NAME="clean"
CLEAN_SCRIPT="$PROJECT_DIR/clean-project.sh"
CLEAN_COMMAND="alias $CLEAN_ALIAS_NAME='bash $CLEAN_SCRIPT'"
BROADCAST_SCRIPT="$PROJECT_DIR/broadcast-test-msgs.sh"
BROADCAST_ALIAS_NAME="sendmsg"
BROADCAST_COMMAND="alias $BROADCAST_ALIAS_NAME='bash $BROADCAST_SCRIPT'"

ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# Remove invalid or legacy aliases
clean_old_aliases() {
  local rc_file="$1"
  if grep -qE "alias +(prov[ -]kafka[ -]test[ -]env)=" "$rc_file"; then
    echo "⚠️ Found legacy or invalid alias in $rc_file. Cleaning it up."
    sed -i.bak '/alias \\(prov[ -]kafka[ -]test[ -]env\\)=/d' "$rc_file"
    echo "✅ Cleaned invalid alias from $rc_file."
  fi
}

# Add alias only if it's not already present
add_alias_if_missing() {
  local rc_file="$1"
  [ -f "$rc_file" ] || touch "$rc_file"
  local added_any=false

  clean_old_aliases "$rc_file"

  if ! grep -Fxq "$ALIAS_COMMAND" "$rc_file"; then
    echo "$ALIAS_COMMAND" >> "$rc_file"
    echo "✅ Alias added to $rc_file for $ALIAS_NAME"
    added_any=true
  else
    echo "✅ Alias already present in $rc_file for $ALIAS_NAME"
  fi

  if ! grep -Fxq "$CLEAN_COMMAND" "$rc_file"; then
    echo "$CLEAN_COMMAND" >> "$rc_file"
    echo "✅ Alias added to $rc_file for $CLEAN_ALIAS_NAME"
    added_any=true
  else
    echo "✅ Alias already present in $rc_file for $CLEAN_ALIAS_NAME"
  fi

  if ! grep -Fxq "$BROADCAST_COMMAND" "$rc_file"; then
    echo "$BROADCAST_COMMAND" >> "$rc_file"
    echo "✅ Alias added to $rc_file for $BROADCAST_ALIAS_NAME"
    added_any=true
  else
    echo "✅ Alias already present in $rc_file for $BROADCAST_ALIAS_NAME"
  fi

  if [ "$added_any" = true ]; then
    echo "🔁 Attempting to source ~/.zshrc and ~/.bashrc in their respective shells..."

echo "⚙️  Spawning zsh to source ~/.zshrc..."
zsh -c "source ~/.zshrc && echo '✅ Sourced ~/.zshrc in zsh'" || echo "⚠️ Failed to source ~/.zshrc in zsh"

    echo "⚙️  Spawning bash to source ~/.bashrc..."
    bash -c "source ~/.bashrc && echo '✅ Sourced ~/.bashrc in bash'" || echo "⚠️ Failed to source ~/.bashrc in bash"

    echo "💡 You may still need to run 'source ~/.zshrc' or 'source ~/.bashrc' manually in your active shell."
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

# Ensure broadcast message script is executable
if [[ -f "$BROADCAST_SCRIPT" ]]; then
  chmod +x "$BROADCAST_SCRIPT" 2>/dev/null || echo "⚠️ Could not chmod $BROADCAST_SCRIPT (already executable or permission issue)"
else
  echo "❌ $BROADCAST_SCRIPT not found. Please create it before continuing."
  exit 1
fi

add_alias_if_missing "$ZSHRC"
add_alias_if_missing "$BASHRC"

echo "🎉 Alias setup attempted."
echo "   ➜ If you see warnings, try running: source ~/.zshrc OR source ~/.bashrc manually."
echo "   ➜ Once sourced, you can use: $ALIAS_NAME, $CLEAN_ALIAS_NAME, or $BROADCAST_ALIAS_NAME"

# Prompt to run
read -rp "🤖 Do you want to run '$SCRIPT_PATH' now? (y/n): " RUN_NOW
RUN_NOW=$(echo "$RUN_NOW" | tr '[:upper:]' '[:lower:]')

if [[ "$RUN_NOW" == "y" ]]; then
  echo -e "\n🚀 Running '$SCRIPT_PATH'..."
  bash -c "$SCRIPT_PATH"
else
  echo "📝 You can run it later by typing the full path or using the alias if available."
fi