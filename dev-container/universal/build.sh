#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found at $ENV_FILE" >&2
  exit 1
fi

DEVPOD_IMAGE=$(grep -E '^DEVPOD_IMAGE=' "$ENV_FILE" | cut -d= -f2- | tr -d '[:space:]')

if [[ -z "$DEVPOD_IMAGE" ]]; then
  echo "Error: DEVPOD_IMAGE not set in .env" >&2
  exit 1
fi

echo "Building image: $DEVPOD_IMAGE"
devcontainer build . --image-name "$DEVPOD_IMAGE"
