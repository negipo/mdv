#!/usr/bin/env bash
input="$(cat)"
cmd="$(echo "$input" | jq -r '.tool_input.command // empty')"

echo "$cmd" | grep -q "git commit" || exit 0

tsc_out="$(npx tsc --noEmit 2>&1)"
if [ $? -ne 0 ]; then
  echo "$tsc_out" >&2
  echo "BLOCKED: TypeScript type errors found. Fix before committing." >&2
  exit 2
fi

exit 0
