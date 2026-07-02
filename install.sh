#!/bin/sh
# install.sh — copy the .autoeng/ framework into a target project.
# Usage: sh install.sh [target-dir] [--force]   (default target: current directory)
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)/.autoeng"
TARGET="${1:-.}"
FORCE="${2:-}"

[ -d "$SRC" ] || { echo "ERROR: source .autoeng not found at $SRC" >&2; exit 2; }
[ -d "$TARGET" ] || { echo "ERROR: target dir does not exist: $TARGET" >&2; exit 2; }

if [ -d "$TARGET/.autoeng" ]; then
  if [ "$FORCE" = "--force" ]; then
    rm -rf "$TARGET/.autoeng"
  else
    echo "ERROR: $TARGET/.autoeng already exists. Re-run with --force to overwrite." >&2
    exit 1
  fi
fi

cp -r "$SRC" "$TARGET/.autoeng"
echo "Installed .autoeng/ into $TARGET"
echo "Next: edit $TARGET/.autoeng/config.sh (set EXECUTOR + CONTROL=enabled),"
echo "then run: sh $TARGET/.autoeng/run.sh adopt && sh $TARGET/.autoeng/run.sh loop"
