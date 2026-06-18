# cc-notify shell add-on (zsh/bash). Source from your shell rc:
#   source /path/to/cc-notify/shell/cc-notify.sh
#
# Optional conveniences for naming sessions at launch. The notifications
# themselves come from the cc-notify Claude Code plugin; this file only adds
# launch helpers. Per-session naming/registration also works via `cc-name`
# (installed to ~/.local/bin by install.sh) from inside a running session.

export CC_NOTIFY_HOME="${CC_NOTIFY_HOME:-$HOME/.config/cc-notify}"

# Launch Claude with a per-session label (announced by the hooks; also set as
# this tab's title). Usage: ccwork <name> [claude args...]
ccwork() {
  if [ -z "$1" ]; then
    echo "usage: ccwork <name> [claude args...]"
    return 1
  fi
  local name="$1"; shift
  printf '\033]0;%s\007' "$name"
  CC_TAB="$name" claude "$@"
}

# Wrapper so a plain `claude` still gets a per-session label: prompts for a name
# (default = current directory) unless one is already set. Skips the prompt for
# non-interactive use and one-shot `-p`/`--print`. `command claude` avoids
# recursing into this function.
claude() {
  if [ -n "$CC_TAB" ] || [ ! -t 0 ]; then
    [ -n "$CC_TAB" ] && printf '\033]0;%s\007' "$CC_TAB"
    command claude "$@"
    return
  fi
  local a
  for a in "$@"; do
    case "$a" in
      -p|--print) command claude "$@"; return ;;
    esac
  done
  local default name
  default="${PWD##*/}"
  printf 'Claude session name [%s]: ' "$default"
  read -r name
  name="${name:-$default}"
  printf '\033]0;%s\007' "$name"
  CC_TAB="$name" command claude "$@"
}
