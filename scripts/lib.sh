#!/bin/sh
# Shared library for cc-notify / cc-done. Sourced, not executed.
#
# Config precedence: $CC_NOTIFY_HOME/config.sh overrides these defaults.

CC_NOTIFY_HOME="${CC_NOTIFY_HOME:-$HOME/.config/cc-notify}"
[ -f "$CC_NOTIFY_HOME/config.sh" ] && . "$CC_NOTIFY_HOME/config.sh"

: "${NEEDS_VOICE:=Bad News}"
: "${DONE_VOICE:=Good News}"
: "${DONE_SOUND:=/System/Library/Sounds/Glass.aiff}"
# Spelled "Clawed" on purpose: macOS `say` reads "Claude" the French way
# ("Clohd"). Override in config.sh if you want something else.
: "${NEEDS_PHRASE:=Clawed}"
: "${DONE_PHRASE:=Clawed}"
: "${VSCODE_BUNDLE_ID:=com.microsoft.VSCode}"
: "${WEZTERM_BUNDLE_ID:=com.github.wez.wezterm}"
: "${WEZTERM_CLI:=/Applications/WezTerm.app/Contents/MacOS/wezterm}"
# Relative speech volume applied to every spoken alert via the `[[volm]]` speech
# command. Empty = system volume (unchanged). A value of 0.0–1.0 lowers speech
# below the system level; it caps at system volume and cannot raise it above.
: "${SAY_VOLUME:=}"
# When set (to anything), appends every raw hook payload to
# $CC_NOTIFY_HOME/debug.log. Off by default so nobody accumulates an
# unbounded log without knowing; turn it on in config.sh while diagnosing.
: "${CC_NOTIFY_DEBUG:=}"

# Reads the hook payload from stdin and sets: payload cwd sid name itermid
#
# Name precedence: cc-names/<sid> (set by cc-name) -> $CC_TAB (set at launch by
# the shell add-on) -> the working-directory basename.
cc_read_payload() {
  payload=$(cat)
  [ -n "$CC_NOTIFY_DEBUG" ] && printf '%s\t%s\n' "$(date)" "$payload" >> "$CC_NOTIFY_HOME/debug.log"
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

# Echoes a runnable `wezterm` CLI path, or nothing if WezTerm isn't installed.
# Prefers the CLI sitting next to the actually-running gui binary ($WEZTERM_
# EXECUTABLE_DIR, set by wezterm itself) over the configured/default path, so
# a differently-named build (e.g. a "WezTerm-dev" fork installed alongside
# the regular app) is talked to via its own binary/mux socket instead of
# accidentally connecting to (or auto-starting) the other one.
_wezterm_cli() {
  [ -n "$WEZTERM_EXECUTABLE_DIR" ] && [ -x "$WEZTERM_EXECUTABLE_DIR/wezterm" ] && { printf '%s' "$WEZTERM_EXECUTABLE_DIR/wezterm"; return; }
  [ -x "$WEZTERM_CLI" ] && { printf '%s' "$WEZTERM_CLI"; return; }
  command -v wezterm 2>/dev/null
}

# Echoes the bundle id of the actually-running wezterm app, derived from
# $WEZTERM_EXECUTABLE_DIR (two levels up from Contents/MacOS is the .app).
# Falls back to the configured/default WEZTERM_BUNDLE_ID. Same reasoning as
# _wezterm_cli: a renamed/forked build has its own bundle id, and activating
# the wrong one raises/launches the wrong app.
_wezterm_bundle_id() {
  if [ -n "$WEZTERM_EXECUTABLE_DIR" ]; then
    _app=$(cd "$WEZTERM_EXECUTABLE_DIR/../.." 2>/dev/null && pwd)
    _id=$(defaults read "$_app/Contents/Info" CFBundleIdentifier 2>/dev/null)
    [ -n "$_id" ] && { printf '%s' "$_id"; return; }
  fi
  printf '%s' "$WEZTERM_BUNDLE_ID"
}

# Returns 0 (skip the alert) only when you're already looking at this session's
# tab: the terminal is frontmost AND its focused tab is this one. iTerm is
# matched by registered session id (or by directory when unregistered);
# WezTerm by its pane id, which is always available via $WEZTERM_PANE (no
# registration needed). Fails open (alerts) for any other terminal.
cc_should_skip() {
  _front=$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)
  case "$_front" in
    iTerm2)
      if [ -n "$itermid" ]; then
        _fid=$(osascript -e 'tell application "iTerm2" to tell current window to tell current session to get id' 2>/dev/null)
        [ "$_fid" = "$itermid" ] && return 0
      else
        _fp=$(osascript -e 'tell application "iTerm2" to tell current window to tell current session to get variable named "path"' 2>/dev/null)
        [ -n "$_fp" ] && [ "$_fp" = "$cwd" ] && return 0
      fi
      ;;
    wezterm-gui)
      _wt=$(_wezterm_cli)
      [ -n "$_wt" ] && [ -n "$WEZTERM_PANE" ] || return 1
      # `cli list`'s per-pane is_active is true for every tab's last-focused
      # pane simultaneously (it does not mean "the tab you're looking at"), so
      # it can't tell tabs apart. list-clients' focused_pane_id is the single
      # pane actually focused in the GUI right now, so use that instead.
      _focused=$("$_wt" cli list-clients --format json 2>/dev/null | jq -r '.[0].focused_pane_id')
      [ "$_focused" = "$WEZTERM_PANE" ] && return 0
      ;;
  esac
  return 1
}

# Posts a clickable banner via terminal-notifier (no-op if it is not installed).
# A VS Code session activates VS Code on click; a WezTerm session jumps to its
# pane directly; an iTerm session jumps to its tab via cc-focus. $1 = subtitle.
# Requires SCRIPT_DIR set by the caller.
cc_notify_banner() {
  _tn=$(command -v terminal-notifier) || return 0
  [ -z "$_tn" ] && return 0
  # -group "$sid" replaces this session's own prior banner instead of
  # stacking a new one, so a persistent alert style doesn't pile up
  # duplicates while a tab goes unchecked.
  if [ -n "$VSCODE_PID" ]; then
    nohup "$_tn" -title "Claude Code" -subtitle "$1" -message "$name" \
      -group "$sid" \
      -activate "$VSCODE_BUNDLE_ID" >/dev/null 2>&1 &
  elif [ -n "$WEZTERM_PANE" ] && _wt=$(_wezterm_cli) && [ -n "$_wt" ]; then
    # $WEZTERM_PANE and $WEZTERM_UNIX_SOCKET are set by wezterm itself (not
    # user-controlled), so it's safe to interpolate them into the executed
    # string. terminal-notifier's own -activate raises the app (and switches
    # macOS Spaces) as part of handling the click; shelling out to `open -a`
    # inside -execute instead doesn't reliably carry that same
    # click-activation privilege, which was letting the Space switch win the
    # race against activate-pane's tab switch. -execute then only has to pick
    # the tab. terminal-notifier runs -execute as its own GUI process's child,
    # with none of wezterm's env vars, so without WEZTERM_UNIX_SOCKET the CLI
    # guesses a socket path from its own PID and fails to connect to the mux
    # entirely (activate-pane silently does nothing).
    nohup "$_tn" -title "Claude Code" -subtitle "$1" -message "$name" \
      -group "$sid" \
      -activate "$(_wezterm_bundle_id)" \
      -execute "WEZTERM_UNIX_SOCKET=\"$WEZTERM_UNIX_SOCKET\" \"$_wt\" cli activate-pane --pane-id $WEZTERM_PANE" >/dev/null 2>&1 &
  else
    # Pass only the Claude session id (a UUID, no shell metacharacters) into the
    # executed string; cc-focus resolves the tab id/name from the state files and
    # hands them to AppleScript as arguments. Keeps user/dir-controlled text out
    # of any shell-evaluated context.
    nohup "$_tn" -title "Claude Code" -subtitle "$1" -message "$name" \
      -group "$sid" \
      -execute "\"$SCRIPT_DIR/cc-focus\" \"$sid\"" >/dev/null 2>&1 &
  fi
}

# Speaks $2 in voice $1 if that voice is installed, else the default voice.
# Detached so a slow novelty voice is never cut short.
cc_say() {
  _phrase="$2"
  [ -n "$SAY_VOLUME" ] && _phrase="[[volm $SAY_VOLUME]]$2"
  if [ -n "$1" ] && say -v '?' 2>/dev/null | grep -q "^$1 "; then
    nohup say -v "$1" "$_phrase" >/dev/null 2>&1 &
  else
    nohup say "$_phrase" >/dev/null 2>&1 &
  fi
}
