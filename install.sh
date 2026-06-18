#!/bin/sh
# Installs the cc-notify shell helpers and the cc-name command. The hooks
# themselves are delivered by the Claude Code plugin (see the marketplace step
# printed below). Safe to re-run.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
CC_NOTIFY_HOME="${CC_NOTIFY_HOME:-$HOME/.config/cc-notify}"

mkdir -p "$CC_NOTIFY_HOME/names" "$CC_NOTIFY_HOME/ids" "$HOME/.local/bin"

cp "$HERE/bin/cc-name" "$HOME/.local/bin/cc-name"
chmod +x "$HOME/.local/bin/cc-name"

if [ ! -f "$CC_NOTIFY_HOME/config.sh" ]; then
  cp "$HERE/config.example.sh" "$CC_NOTIFY_HOME/config.sh"
fi

echo "Installed:"
echo "  - cc-name        -> ~/.local/bin/cc-name   (ensure ~/.local/bin is on PATH)"
echo "  - config         -> $CC_NOTIFY_HOME/config.sh"
echo "  - state dirs     -> $CC_NOTIFY_HOME/{names,ids}"
echo
echo "Next steps:"
echo
echo "1) Shell helpers (optional: ccwork + the claude launch prompt). Add to ~/.zshrc:"
echo "   echo 'source \"$HERE/shell/cc-notify.sh\"' >> ~/.zshrc"
echo
echo "2) Install the plugin in Claude Code (delivers the hooks):"
echo "   /plugin marketplace add $HERE"
echo "   /plugin install cc-notify@cc-notify"
echo
echo "3) Check dependencies and macOS permissions:"
echo "   sh \"$HERE/doctor.sh\""
