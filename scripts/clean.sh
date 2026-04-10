#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
  DRY_RUN=true
  echo "[dry-run] 削除対象の表示のみ行います"
  echo
fi

TARGETS=(
  build
  tmp
  .worktrees
  .superpowers
)

FILES=(
  .DS_Store
)

GLOBS=(
  "mdv-*.zip"
  "mdv-*.dmg"
  "*.profraw"
)

total=0

for dir in "${TARGETS[@]}"; do
  if [ -d "$dir" ]; then
    size=$(du -sm "$dir" 2>/dev/null | cut -f1)
    total=$((total + size))
    if $DRY_RUN; then
      echo "  rm -rf $dir/ (${size}MB)"
    else
      rm -rf "$dir"
      echo "  removed $dir/ (${size}MB)"
    fi
  fi
done

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    size=$(du -sm "$file" 2>/dev/null | cut -f1)
    total=$((total + size))
    if $DRY_RUN; then
      echo "  rm $file"
    else
      rm -f "$file"
      echo "  removed $file"
    fi
  fi
done

for glob in "${GLOBS[@]}"; do
  for file in $glob; do
    if [ -f "$file" ]; then
      size=$(du -sm "$file" 2>/dev/null | cut -f1)
      total=$((total + size))
      if $DRY_RUN; then
        echo "  rm $file (${size}MB)"
      else
        rm -f "$file"
        echo "  removed $file (${size}MB)"
      fi
    fi
  done
done

echo
if $DRY_RUN; then
  echo "合計: 約${total}MB が削除可能"
else
  echo "合計: 約${total}MB を削除しました"
fi
