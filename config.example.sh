# cc-notify configuration. Copy to $CC_NOTIFY_HOME/config.sh
# (default ~/.config/cc-notify/config.sh) and uncomment what you want to change.
# install.sh copies this for you on first run.
#
# Voices: run `say -v '?'` to list installed voices. The novelty singing voices
# "Bad News" / "Good News" may need installing via
# System Settings > Accessibility > Spoken Content > System Voices.
# If a configured voice is not installed, cc-notify falls back to the default
# system voice automatically.

# Voice for the "needs you" alert.
# NEEDS_VOICE="Bad News"

# Voice for the "done" alert.
# DONE_VOICE="Good News"

# Sound played before the "done" voice.
# DONE_SOUND="/System/Library/Sounds/Glass.aiff"

# What each alert speaks. Keep short; the banner still shows the session name.
# Default is "Clawed" so macOS `say` pronounces it right ("Claude" comes out
# French-ish, "Clohd").
# NEEDS_PHRASE="Clawed"
# DONE_PHRASE="Clawed"

# Bundle id activated on click for VS Code sessions.
# VSCODE_BUNDLE_ID="com.microsoft.VSCode"

# Path to the wezterm CLI binary, for WezTerm sessions. Defaults to the
# standard app-bundle location; override if you built from source or renamed
# the app.
# WEZTERM_CLI="/Applications/WezTerm.app/Contents/MacOS/wezterm"

# Relative speech volume for spoken alerts (0.0–1.0), applied via the `[[volm]]`
# speech command. Empty/unset = system volume. Lowers speech below the system
# level only — it caps at system volume and cannot make speech louder than it.
# SAY_VOLUME="0.11"
