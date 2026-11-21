#!/usr/bin/env bash
# Runs a GUILDA rule hook (.claude/hooks/<script>.py) with Python 3.
# Used by .claude/settings.json on macOS, Linux and Windows (Git Bash).
# If no Python 3 is found, the tool call is let through with a warning
# instead of blocking every command.
script="${0%/*}/$1"
for py in python3 python py; do
  if command -v "$py" >/dev/null 2>&1 &&
     "$py" -c 'import sys; sys.exit(sys.version_info[0] != 3)' >/dev/null 2>&1; then
    exec "$py" -B "$script"
  fi
done
echo "{\"systemMessage\": \"GUILDA hook $1 skipped: Python 3 not found, so this rule was not checked.\"}"
exit 0
