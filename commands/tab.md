---
allowed-tools: Bash("${CLAUDE_PLUGIN_ROOT}"/bin/cc-name:*)
argument-hint: <name>
description: Name this Claude session's tab for cc-notify (announce + click-to-focus)
---
!`"${CLAUDE_PLUGIN_ROOT}"/bin/cc-name $ARGUMENTS`
