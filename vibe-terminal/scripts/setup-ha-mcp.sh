#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
#
# Register ha-mcp (https://github.com/homeassistant-ai/ha-mcp) as a stdio MCP
# server in Mistral Vibe's user config ($VIBE_HOME/config.toml), so Vibe can
# read states, call services and manage automations, scripts and dashboards.
#
# The entry points at /usr/local/bin/ha-mcp-launch, which reads the
# Supervisor token at launch time. The token is therefore never written to
# config.toml (which is in /data and in Home Assistant backups).
#
# Only the [[mcp_servers]] entry named "home_assistant" is touched; the rest
# of config.toml, including the user's own servers and comments, is kept.

MCP_SERVER_NAME="home_assistant"

_upsert_vibe_mcp_entry() {
    # $1 = config path, $2 = ha-mcp version, $3 = "add" or "remove"
    python3 - "$1" "$2" "$3" "$MCP_SERVER_NAME" <<'PY'
import sys
from pathlib import Path

import tomlkit

path, version, mode, name = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
doc = tomlkit.parse(path.read_text(encoding="utf-8")) if path.exists() else tomlkit.document()

servers = doc.get("mcp_servers")
if servers is None:
    servers = tomlkit.aot()
elif not isinstance(servers, tomlkit.items.AoT):
    sys.exit("config.toml: mcp_servers is not an array of tables ([[mcp_servers]])")

kept = [s for s in servers if s.get("name") != name]
new = tomlkit.aot()
for s in kept:
    new.append(s)

if mode == "add":
    entry = tomlkit.table()
    entry["name"] = name
    entry["transport"] = "stdio"
    entry["command"] = "/usr/local/bin/ha-mcp-launch"
    entry["args"] = [version]
    # First start may resolve ha-mcp's dependencies; the add-on pre-warms
    # them at boot, this is only the safety margin.
    entry["startup_timeout_sec"] = 180.0
    entry["tool_timeout_sec"] = 120.0
    entry["prompt"] = (
        "Home Assistant on this machine (via the Supervisor). Use these tools "
        "to read entity states, call services and create or edit automations, "
        "scripts and dashboards."
    )
    new.append(entry)

if len(new):
    doc["mcp_servers"] = new
elif "mcp_servers" in doc:
    del doc["mcp_servers"]

tmp = path.with_suffix(".toml.tmp")
tmp.write_text(tomlkit.dumps(doc), encoding="utf-8")
tmp.replace(path)
PY
}

configure_ha_mcp_server() {
    local config_file="${VIBE_HOME:-$HOME/.vibe}/config.toml"
    mkdir -p "$(dirname "$config_file")"

    if [ "$(bashio::config 'enable_ha_mcp' 'true')" != "true" ]; then
        bashio::log.info "ha-mcp integration is disabled in configuration"
        _upsert_vibe_mcp_entry "$config_file" "" remove \
            || bashio::log.warning "Could not remove the ha-mcp entry from ${config_file}"
        return 0
    fi

    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "SUPERVISOR_TOKEN not available - ha-mcp setup skipped"
        return 0
    fi

    local version
    version=$(bashio::config 'ha_mcp_version' '7.11.0')

    if _upsert_vibe_mcp_entry "$config_file" "$version" add; then
        bashio::log.info "ha-mcp ${version} registered in ${config_file}"
    else
        bashio::log.warning "Failed to register ha-mcp in ${config_file} - continuing without MCP integration"
        return 0
    fi

    # Pre-warm the uv environment in the background so the first MCP
    # connection doesn't hit Vibe's startup timeout
    (timeout 900 /usr/local/bin/ha-mcp-launch "$version" --prewarm >/dev/null 2>&1 || true) &
    bashio::log.info "Pre-warming ha-mcp environment in background"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
