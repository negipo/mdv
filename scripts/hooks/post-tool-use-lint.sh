#!/usr/bin/env bash
input="$(cat)"
file="$(echo "$input" | jq -r '.tool_input.file_path // empty')"
[ -z "$file" ] && exit 0
[ ! -f "$file" ] && exit 0

diag=""

case "$file" in
  *.ts|*.mjs)
    biome format --write "$file" >/dev/null 2>&1 || true
    biome_out="$(biome check "$file" 2>&1 | head -20)"
    ox_out="$(oxlint "$file" 2>&1 | head -20)"
    [ -n "$biome_out" ] && diag="$biome_out"
    [ -n "$ox_out" ] && diag="$diag
$ox_out"
    ;;
  *.swift)
    swift_out="$(swiftlint lint --quiet "$file" 2>&1 | head -20)"
    [ -n "$swift_out" ] && diag="$swift_out"
    ;;
esac

if [ -n "$diag" ]; then
  jq -Rn --arg msg "$diag" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $msg
    }
  }'
fi

exit 0
