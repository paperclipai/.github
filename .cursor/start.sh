#!/usr/bin/env bash
set -euo pipefail

port="${PORT:-4321}"
if curl -sf --max-time 2 "http://127.0.0.1:${port}/health" >/dev/null; then
  echo "profile preview already listening on ${port}"
  exit 0
fi

export PORT="$port"
export README_PATH="${README_PATH:-/workspace/README.md}"
exec node /opt/profile-preview/server.mjs
