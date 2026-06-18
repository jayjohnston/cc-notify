#!/bin/sh
# Checks dependencies and reminds about the manual macOS permissions.

echo "== cc-notify doctor =="
echo
echo "Dependencies:"
for dep in terminal-notifier jq osascript say afplay; do
  if command -v "$dep" >/dev/null 2>&1; then
    echo "  ok    $dep"
  else
    echo "  MISS  $dep"
  fi
done

echo
echo "Optional singing voices (used by the default config):"
for v in "Bad News" "Good News"; do
  if say -v '?' 2>/dev/null | grep -q "^$v "; then
    echo "  ok    voice: $v"
  else
    echo "  MISS  voice: $v  (System Settings > Accessibility > Spoken Content > System Voices)"
  fi
done

echo
echo "Install missing CLI deps with:"
echo "  brew install terminal-notifier jq"
echo
echo "Manual macOS permissions (cannot be auto-granted):"
echo "  1. Notifications: System Settings > Notifications > terminal-notifier > Allow Notifications"
echo "     (the first banner click may route you here)."
echo "  2. Automation: System Settings > Privacy & Security > Automation — allow terminal-notifier"
echo "     to control iTerm2, System Events, and Visual Studio Code (approve the first-click prompt)."
echo "  3. Spaces: System Settings > Desktop & Dock > Mission Control — enable"
echo "     'When switching to an application, switch to a Space with open windows for the application'"
echo "     so a click can pull you to the tab's Space."
