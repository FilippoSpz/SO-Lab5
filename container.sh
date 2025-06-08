#!/bin/bash

set -e

if [ $# -lt 2 ]; then
  exit 1
fi

CONF_FILE="$1"
COMMAND="$2"
shift 2

CONTAINER_ROOT=$(mktemp -d)

trap
 fusermount -u "$CONTAINER_ROOT"/* 2>/dev/null || true
  rm -rf "$CONTAINER_ROOT"

IFS=$'\n'

for line in $(cat "$CONF_FILE"); do
  SRC=$(echo "$line" | awk '{print $1}')
  DST=$(echo "$line" | awk '{print $2}')
  FULL_DST="$CONTAINER_ROOT$DST"

  if [ -d "$SRC" ]; then
    mkdir -p "$FULL_DST"
    bindfs --no-allow-other "$SRC" "$FULL_DST"
  elif [ -f "$SRC" ]; then
    mkdir -p "$(dirname "$FULL_DST")"
    cp "$SRC" "$FULL_DST"
  else
    exit 1
  fi
done

fakechroot chroot "$CONTAINER_ROOT" "$COMMAND" "$@"