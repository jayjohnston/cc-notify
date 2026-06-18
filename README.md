# cc-notify

Audible + banner notifications for [Claude Code](https://claude.com/claude-code), so you know which
session needs you across many tabs and projects — and clicking the banner jumps straight to the
right iTerm tab (or raises VS Code).

Built for running several Claude sessions at once. **macOS only.**

- **Needs you** (permission prompt / question): a spoken alert + a clickable banner.
- **Done** (turn finished): a sound + a different voice + a clickable banner.
- **Click → focus**: iTerm sessions jump to their exact tab (by stable session id, title-proof);
  VS Code sessions raise VS Code. Works across Spaces.
- **Per-session names**: name a tab so the alert says "perf-pass" instead of the directory — even
  with multiple sessions in the same repo.
- **Quiet when you're looking**: muted on the tab you're already viewing.

## Requirements

- macOS, with `say`, `afplay`, `osascript` (built in).
- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) and `jq`:
  `brew install terminal-notifier jq`
- iTerm2 for tab-jumping (VS Code is auto-detected for its own sessions).
- Optional: the novelty voices "Bad News" / "Good News" (System Settings → Accessibility → Spoken
  Content → System Voices). Without them it falls back to the default voice.

## Install

```sh
git clone <this-repo> ~/gitrepos/cc-notify
cd ~/gitrepos/cc-notify
sh install.sh        # installs cc-name + config + state dirs, prints next steps
sh doctor.sh         # checks deps + lists the macOS permissions to grant
```

Then, in Claude Code, install the plugin that delivers the hooks:

```
/plugin marketplace add ~/gitrepos/cc-notify
/plugin install cc-notify@cc-notify
```

The plugin's hooks **merge** with any hooks you already have — they won't replace them.

Optional shell helpers (the `ccwork` launcher and the naming prompt on plain `claude`):

```sh
echo 'source "$HOME/gitrepos/cc-notify/shell/cc-notify.sh"' >> ~/.zshrc
```

### Manual macOS permissions (one-time)

`doctor.sh` lists these; they can't be scripted:

1. **Notifications** — allow `terminal-notifier` (the first banner click routes you to Settings).
2. **Automation** — allow `terminal-notifier` to control iTerm2 / System Events / VS Code (approve
   the first-click prompt).
3. **Spaces** — System Settings → Desktop & Dock → Mission Control → enable *"When switching to an
   application, switch to a Space with open windows for the application"* so a click can change Space.

## Usage

Notifications work immediately, named by the session's directory. Click-to-jump is **automatic**: a
`SessionStart` hook registers each session's iTerm tab on launch (and again on `--resume`, so the id
never goes stale).

To give a session a real name:

- **At launch:** `ccwork perf-pass` (instead of `claude`), or just run `claude` and answer the
  name prompt.
- **Mid-session:** in the Claude input box, run `!cc-name perf-pass`. (Also re-registers the tab —
  handy if the session started while iTerm wasn't frontmost, so auto-registration skipped it.)

## Configure

Edit `~/.config/cc-notify/config.sh` (created by `install.sh`). You can change the voices, the
"done" sound, the spoken phrases, and the VS Code bundle id. See `config.example.sh`.

## How it works

- The **plugin** registers a `Notification` hook (`scripts/cc-notify`), a `Stop` hook
  (`scripts/cc-done`), and a `SessionStart` hook (`scripts/cc-register`, which records the launching
  tab's iTerm id). Each reads the hook's JSON (`session_id`, `cwd`), and the notify/done scripts
  resolve the name, post the banner, and speak — all detached so nothing blocks Claude.
- **Names/ids** live in `~/.config/cc-notify/{names,ids}`, keyed by Claude's `session_id`, written by
  `cc-name`. The plugin and the `cc-name`/shell helpers communicate only through these files, so they
  are fully decoupled.
- **Click routing**: `scripts/cc-focus` selects the iTerm tab by its registered session id (immune to
  Claude's auto-changing tab titles); VS Code sessions use `terminal-notifier -activate`.

## Limitations

- macOS only.
- Tab-jump targets iTerm2; other terminals fall back to just speaking + a banner.
- Precise tab-jump relies on auto-registration at session start, which needs iTerm frontmost then.
  If you launch with another app focused, run `!cc-name` once; otherwise the click falls back to
  just focusing iTerm.

## Security

- **No network calls, no telemetry** — everything runs locally.
- The plugin runs its bundled shell scripts on every `Notification`/`Stop` event and uses macOS
  Automation to focus iTerm2 / VS Code. It's all in `scripts/` — review before installing.
- The banner's **click action executes only a fixed script path plus the Claude session id** (a
  UUID). Session names and directory names are passed to AppleScript as arguments, never placed in a
  shell-evaluated string, so a hostile name cannot inject commands.
- State is plain files under `~/.config/cc-notify` (the names you set and iTerm tab ids).

## License

MIT
