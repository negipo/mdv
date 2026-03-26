#!/usr/bin/env bash
input="$(cat)"
file="$(echo "$input" | jq -r '.tool_input.file_path // empty')"
[ -z "$file" ] && exit 0

protected="biome.json .swiftlint.yml"
basename="$(basename "$file")"
for p in $protected; do
  if [ "$basename" = "$p" ]; then
    echo "BLOCKED: $p is a protected linter config file. Do not modify directly." >&2
    exit 2
  fi
done

exit 0
