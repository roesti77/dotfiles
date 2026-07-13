#!/usr/bin/env bash
# macos-notify.sh — surface Claude Code Notification/Stop events as macOS
# banners, replacing supacode's agent presence badges. No-op inside supacode
# (its own hooks own presence there) so notifications never fire twice.
set -euo pipefail

# Skip inside supacode. SUPACODE_SOCKET_PATH is injected by its shell
# integration; __CFBundleIdentifier is set by macOS at process start.
if [ -n "${SUPACODE_SOCKET_PATH:-}" ]; then exit 0; fi
if [ "${__CFBundleIdentifier:-}" = "app.supabit.supacode" ]; then exit 0; fi

jq=$(command -v jq || true)
[ -n "$jq" ] || exit 0

payload=$(cat)
event=$(printf '%s' "$payload" | "$jq" -r '.hook_event_name // empty' 2>/dev/null || true)
cwd=$(printf '%s' "$payload" | "$jq" -r '.cwd // empty' 2>/dev/null || true)
dir=$(basename "${cwd:-$PWD}")

case "$event" in
Notification)
	msg=$(printf '%s' "$payload" | "$jq" -r '.message // "Notification"' 2>/dev/null || true)
	[ -n "$msg" ] || msg="Notification"
	;;
Stop)
	msg="Done: $dir"
	;;
*)
	exit 0
	;;
esac

# Include the zellij session name when running inside zellij.
title="Claude Code${ZELLIJ_SESSION_NAME:+ · $ZELLIJ_SESSION_NAME}"

# Pass text as argv, never interpolated into the AppleScript source, so payload
# content cannot break out of the string.
osascript - "$title" "$msg" <<'APPLESCRIPT' || true
on run argv
	display notification (item 2 of argv) with title (item 1 of argv) sound name "Glass"
end run
APPLESCRIPT
