# cc-notify

Audible + banner notifications for [Claude Code](https://claude.com/claude-code), so you know which
session needs you across many tabs and projects — and clicking the banner jumps straight to the
right iTerm tab or WezTerm pane (or raises VS Code).

Built for running several Claude sessions at once. **macOS only.**

- **Needs you** (permission prompt / question): a spoken alert + a clickable banner.
- **Done** (turn finished): a sound + a different voice + a clickable banner.
- **Click → focus**: iTerm sessions jump to their exact tab (by stable session id, title-proof);
  WezTerm sessions jump to their exact pane; VS Code sessions raise VS Code. Works across Spaces.
- **Per-session names**: name a tab so the alert says "perf-pass" instead of the directory — even
  with multiple sessions in the same repo.
- **Quiet when you're looking**: muted on the tab you're already viewing.

**Works with:** iTerm2, WezTerm, VS Code.

## Requirements

- macOS, with `say`, `afplay`, `osascript` (built in).
- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) and `jq`:
  `brew install terminal-notifier jq`
- iTerm2 or WezTerm for tab/pane-jumping (VS Code is auto-detected for its own sessions).
- Optional: the novelty voices "Bad News" / "Good News" (System Settings → Accessibility → Spoken
  Content → System Voices). Without them it falls back to the default voice.

## Install

```sh
git clone git@github.com:jayjohnston/cc-notify.git ~/gitrepos/cc-notify
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

Run those two commands in your own personal/user-scope Claude Code session — not inside a
shared team project's tracked `.claude/settings.json`. This is a personal, macOS-only tool;
enabling it there just adds dead weight for teammates on other OSes and leaks your setup into
version control.

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
- **Mid-session:** in the Claude input box, run `/tab perf-pass` (slash command shipped by the
  plugin), or the equivalent `!cc-name perf-pass`. (Either also re-registers the tab — handy if the
  session started while iTerm wasn't frontmost, so auto-registration skipped it.)

  `/tab` is the memorable form and needs nothing on your `PATH` — it calls the bundled `cc-name` via
  the plugin. `!cc-name` is lighter (runs in your shell, no model turn) but requires `install.sh` to
  have put `cc-name` on `PATH`.

## Configure

Edit `~/.config/cc-notify/config.sh` (created by `install.sh`). You can change the voices, the
"done" sound, the spoken phrases, and the VS Code bundle id. See `config.example.sh`.

## Troubleshooting

**It notifies me but doesn't jump to the tab:**

1. Run `sh doctor.sh` — checks `terminal-notifier`/`jq` and reprints the manual permissions above.
2. **Automation permission** (the most common cause): System Settings → Privacy & Security →
   Automation → `terminal-notifier` must be allowed to control iTerm2 and System Events. If
   `terminal-notifier` isn't listed there at all, the first-click prompt was probably dismissed —
   reset it with `tccutil reset AppleEvents com.googlecode.iterm2` and click a banner again to
   re-trigger the prompt.
3. **Notifications permission**: System Settings → Notifications → `terminal-notifier` must be
   allowed to show banners/alerts (not "None").
4. **Does clicking bring iTerm2 forward at all, or does nothing happen?** Nothing happening points at
   #2/#3. Coming forward on the *wrong* tab means the session's tab id was never registered (it was
   launched while iTerm2 wasn't frontmost) and it also has no name set — run `!cc-name <name>` (or
   `/tab <name>`) once and it'll jump correctly from then on (see Limitations).
5. **Spaces**: if iTerm2 lives on another Space, confirm the Mission Control setting above is
   enabled — otherwise a click can bring iTerm2 forward without switching you to its Space.

## How it works

- The **plugin** registers a `Notification` hook (`scripts/cc-notify`), a `Stop` hook
  (`scripts/cc-done`), and a `SessionStart` hook (`scripts/cc-register`, which records the launching
  tab's iTerm id). Each reads the hook's JSON (`session_id`, `cwd`), and the notify/done scripts
  resolve the name, post the banner, and speak — all detached so nothing blocks Claude.
- The **plugin** also ships the `/tab <name>` slash command (`commands/tab.md`), which invokes the
  bundled `bin/cc-name` via `${CLAUDE_PLUGIN_ROOT}` — so naming works from a plain plugin install
  without `cc-name` on `PATH`.
- **Names/ids** live in `~/.config/cc-notify/{names,ids}`, keyed by Claude's `session_id`, written by
  `cc-name`. The plugin and the `cc-name`/shell helpers communicate only through these files, so they
  are fully decoupled.
- **Click routing**: `scripts/cc-focus` selects the iTerm tab by its registered session id (immune to
  Claude's auto-changing tab titles); WezTerm sessions run `wezterm cli activate-pane` directly
  (its pane id is already in `$WEZTERM_PANE`, no registration needed); VS Code sessions use
  `terminal-notifier -activate`.

## Limitations

- macOS only.
- Tab/pane-jump targets iTerm2 and WezTerm; other terminals fall back to just speaking + a banner.
- Precise iTerm tab-jump relies on auto-registration at session start, which needs iTerm frontmost
  then. If you launch with another app focused, run `!cc-name` once; otherwise the click falls back
  to just focusing iTerm. WezTerm needs no registration (its pane id is always in `$WEZTERM_PANE`).
- WezTerm's "quiet when you're looking" check can't see across multiple WezTerm windows — it only
  knows whether *a* pane is the one Claude is running in, not whether that pane's window is the
  frontmost one.

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
