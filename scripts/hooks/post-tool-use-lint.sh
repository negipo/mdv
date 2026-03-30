#!/usr/bin/env bash
set -o pipefail

input="$(cat)"
file="$(echo "$input" | jq -r '.tool_input.file_path // empty')"
[ -z "$file" ] && exit 0
[ ! -f "$file" ] && exit 0

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
rel="${file#"$repo_root"/}"

diag=""
rc=0

case "$rel" in
  js/*|tests/*|tsconfig.json|biome.json|package.json|esbuild.config.mjs)
    biome format --write "$file" >/dev/null 2>&1 || true
    biome_out="$(biome check "$file" 2>&1 | head -20)" || rc=1
    ox_out="$(oxlint "$file" 2>&1 | head -20)" || rc=1
    [ -n "$biome_out" ] && diag="$biome_out"
    [ -n "$ox_out" ] && diag="$diag
$ox_out"
    ;;
  mdv/*|mdvTests/*)
    swift_out="$(swiftlint lint --quiet "$file" 2>&1 | head -20)" || rc=1
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

exit "$rc"
