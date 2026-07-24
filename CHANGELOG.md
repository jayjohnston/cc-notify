# Changelog

## [0.2.2] - 2026-07-24

### Fixed
- WezTerm sessions now announce/display the tab's live `tab_title` (e.g. renamed via the tab-title skill or `wezterm cli set-tab-title`) instead of the name cached at launch/registration, which could go stale as soon as the tab was renamed later in the session.

## [0.2.0] - 2026-07-20

### Added
- Initial public release.
- Spoken + banner alerts on `Notification` ("needs you") and `Stop` ("done") hook events.
- Click-to-focus: jumps to the exact iTerm2 tab or WezTerm pane, or raises VS Code.
- Per-session naming via `ccwork <name>`, `/tab <name>`, or `!cc-name <name>`.
- Quiet-when-looking: muted on the tab you're already viewing.
