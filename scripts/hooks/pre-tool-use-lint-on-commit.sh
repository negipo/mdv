#!/usr/bin/env bash
input="$(cat)"
cmd="$(echo "$input" | jq -r '.tool_input.command // empty')"

echo "$cmd" | grep -q "git commit" || exit 0

lint_out="$(npm run lint:js 2>&1)"
if [ $? -ne 0 ]; then
  echo "$lint_out" >&2
  echo "BLOCKED: Lint errors found. Fix before committing." >&2
  exit 2
fi

exit 0
