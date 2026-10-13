#!/usr/bin/env bash
# Start the image, wait for /health, then stop it. Used by CI and by `make smoke`.
set -euo pipefail
IMAGE="$1"
NAME="smoke-$$"

docker run -d --name "$NAME" -p 18080:8080 "$IMAGE" >/dev/null
trap 'docker rm -f "$NAME" >/dev/null' EXIT

for i in $(seq 1 20); do
  if curl -fsS http://localhost:18080/health; then
    echo; echo "Smoke test passed"
    exit 0
  fi
  sleep 1
done
echo "Smoke test FAILED"; docker logs "$NAME"; exit 1
