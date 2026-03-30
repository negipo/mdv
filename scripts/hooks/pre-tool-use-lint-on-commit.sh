#!/usr/bin/env bash
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="$repo_root/node_modules/.bin:$PATH"

input="$(cat)"
cmd="$(echo "$input" | jq -r '.tool_input.command // empty')"

echo "$cmd" | grep -q "git commit" || exit 0

tsc_out="$(tsc --noEmit 2>&1)"
if [ $? -ne 0 ]; then
  echo "$tsc_out" >&2
  echo "BLOCKED: TypeScript type errors found. Fix before committing." >&2
  exit 2
fi

biome_out="$(biome check js/ tests/ 2>&1)"
if [ $? -ne 0 ]; then
  echo "$biome_out" >&2
  echo "BLOCKED: Biome lint errors found. Fix before committing." >&2
  exit 2
fi

ox_out="$(oxlint js/ tests/ 2>&1)"
if [ $? -ne 0 ]; then
  echo "$ox_out" >&2
  echo "BLOCKED: Oxlint errors found. Fix before committing." >&2
  exit 2
fi

exit 0
