#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."

mcp_url="${NT_HELPER_MCP_URL:-http://127.0.0.1:3847/mcp}"
if ! curl --silent --show-error --fail --max-time 2 \
  --request OPTIONS "$mcp_url" >/dev/null; then
  echo "Hardware tests require nt_helper connected to the physical NT with its MCP status light green." >&2
  echo "MCP endpoint unavailable: $mcp_url" >&2
  exit 2
fi

NT_HELPER_MCP_URL="$mcp_url" \
  flutter test \
  hardware_test/specification_repeat_metadata_hardware_test.dart \
  --reporter expanded
