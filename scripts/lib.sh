#!/bin/sh
# Shared library for cc-notify / cc-done. Sourced, not executed.
#
# Config precedence: $CC_NOTIFY_HOME/config.sh overrides these defaults.

CC_NOTIFY_HOME="${CC_NOTIFY_HOME:-$HOME/.config/cc-notify}"
[ -f "$CC_NOTIFY_HOME/config.sh" ] && . "$CC_NOTIFY_HOME/config.sh"

: "${NEEDS_VOICE:=Bad News}"
: "${DONE_VOICE:=Good News}"
: "${DONE_SOUND:=/System/Library/Sounds/Glass.aiff}"
: "${NEEDS_PHRASE:=Claude}"
: "${DONE_PHRASE:=Claude}"
: "${VSCODE_BUNDLE_ID:=com.microsoft.VSCode}"

# Reads the hook payload from stdin and sets: payload cwd sid name itermid
#
# Name precedence: cc-names/<sid> (set by cc-name) -> $CC_TAB (set at launch by
# the shell add-on) -> the working-directory basename.
cc_read_payload() {
  payload=$(cat)
  cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
  sid=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)

  if [ -n "$sid" ] && [ -f "$CC_NOTIFY_HOME/names/$sid" ]; then
    name=$(cat "$CC_NOTIFY_HOME/names/$sid" 2>/dev/null)
  elif [ -n "$CC_TAB" ]; then
    name="$CC_TAB"
  else
    name=$(basename "$cwd" 2>/dev/null)
  fi
  [ -z "$name" ] && name="a session"

  itermid=""
  [ -n "$sid" ] && [ -f "$CC_NOTIFY_HOME/ids/$sid" ] && itermid=$(cat "$CC_NOTIFY_HOME/ids/$sid" 2>/dev/null)
}

# Returns 0 (skip the alert) only when you're already looking at this session's
# iTerm tab: iTerm2 is frontmost AND its focused session is this one (matched by
# registered iTerm id, or by directory when unregistered). Fails open (alerts).
cc_should_skip() {
  _front=$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)
  [ "$_front" = "iTerm2" ] || return 1
  if [ -n "$itermid" ]; then
    _fid=$(osascript -e 'tell application "iTerm2" to tell current window to tell current session to get id' 2>/dev/null)
    [ "$_fid" = "$itermid" ] && return 0
  else
    _fp=$(osascript -e 'tell application "iTerm2" to tell current window to tell current session to get variable named "path"' 2>/dev/null)
    [ -n "$_fp" ] && [ "$_fp" = "$cwd" ] && return 0
  fi
  return 1
}

# Posts a clickable banner via terminal-notifier (no-op if it is not installed).
# A VS Code session activates VS Code on click; an iTerm session jumps to its
# tab via cc-focus. $1 = subtitle. Requires SCRIPT_DIR set by the caller.
cc_notify_banner() {
  _tn=$(command -v terminal-notifier) || return 0
  [ -z "$_tn" ] && return 0
  if [ -n "$VSCODE_PID" ]; then
    nohup "$_tn" -title "Claude Code" -subtitle "$1" -message "$name" \
      -activate "$VSCODE_BUNDLE_ID" >/dev/null 2>&1 &
  else
    nohup "$_tn" -title "Claude Code" -subtitle "$1" -message "$name" \
      -execute "\"$SCRIPT_DIR/cc-focus\" \"$itermid\" \"$name\"" >/dev/null 2>&1 &
  fi
}

# Speaks $2 in voice $1 if that voice is installed, else the default voice.
# Detached so a slow novelty voice is never cut short.
cc_say() {
  if [ -n "$1" ] && say -v '?' 2>/dev/null | grep -q "^$1 "; then
    nohup say -v "$1" "$2" >/dev/null 2>&1 &
  else
    nohup say "$2" >/dev/null 2>&1 &
  fi
}
