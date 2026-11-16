#!/bin/bash
#
# ha-mcp-launch VERSION [--prewarm]
#
# Starts ha-mcp as a stdio MCP server for Mistral Vibe. Vibe starts MCP
# servers with only a minimal environment (HOME, PATH, ...), so the
# Supervisor token and the uv cache location are set here, at launch, instead
# of being stored in Vibe's config.toml.

set -euo pipefail

version="${1:?usage: ha-mcp-launch VERSION [--prewarm]}"

token="${SUPERVISOR_TOKEN:-}"
if [ -z "$token" ] && [ -r /run/s6/container_environment/SUPERVISOR_TOKEN ]; then
    token=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN)
fi
if [ -z "$token" ]; then
    echo "ha-mcp-launch: no Supervisor token available (not running as a Home Assistant add-on?)" >&2
    exit 1
fi

export HOMEASSISTANT_URL="http://supervisor/core"
export HOMEASSISTANT_TOKEN="$token"
export XDG_CACHE_HOME="/data/.cache"
export XDG_DATA_HOME="/data/.local/share"

uvx_args=(--python /usr/bin/python3 --index-strategy unsafe-best-match)

if [ "${2:-}" = "--prewarm" ]; then
    exec uvx "${uvx_args[@]}" --from "ha-mcp@${version}" python -c ""
fi

exec uvx "${uvx_args[@]}" "ha-mcp@${version}"
