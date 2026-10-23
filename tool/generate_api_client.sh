#!/usr/bin/env bash
# Exports the OpenAPI document from a niscala-api git ref and regenerates the
# Dart client in packages/niscala_api/. Needs uv and Docker.
#
# Usage: tool/generate_api_client.sh [ref]
#   ref  git ref of the checkout at NISCALA_API_DIR (default: origin/main)
#
# NISCALA_API_DIR defaults to ~/Documents/dev/python/niscala-api. The checkout's
# working tree is never touched: the ref is exported with git archive.
set -euo pipefail

ref="${1:-origin/main}"
api_dir="${NISCALA_API_DIR:-$HOME/Documents/dev/python/niscala-api}"
root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

git -C "$api_dir" fetch --quiet origin
git -C "$api_dir" archive "$ref" | tar -x -C "$work"

# FastAPI declares a 422 body (HTTPValidationError) that is not what the API
# returns (every error is {code, field, message}), and the Dart generator cannot
# emit its anyOf "loc" field. Drop both from the exported document.
(cd "$work" && uv run --quiet python -c '
import json
from app.main import app

doc = app.openapi()
for path in doc["paths"].values():
    for operation in path.values():
        operation.get("responses", {}).pop("422", None)
for name in ("HTTPValidationError", "ValidationError"):
    doc["components"]["schemas"].pop(name, None)
print(json.dumps(doc, indent=2, sort_keys=True))
') > "$root/api/openapi.json"

rm -rf "$root/packages/niscala_api"
docker run --rm --user "$(id -u):$(id -g)" -v "$root:/work" \
  openapitools/openapi-generator-cli:v7.10.0 generate \
  -i /work/api/openapi.json -g dart -o /work/packages/niscala_api \
  --additional-properties=pubName=niscala_api,pubLibrary=niscala_api

echo "Generated from $api_dir at $(git -C "$api_dir" rev-parse --short "$ref")"
