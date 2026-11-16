#!/bin/bash

# tmux-status.sh — status bar data for Vibe Terminal. Must be fast (<1s).

auth_status() {
    local env_file="${VIBE_HOME:-$HOME/.vibe}/.env"
    if [ -n "${MISTRAL_API_KEY:-}" ] \
        || { [ -f "$env_file" ] && grep -q '^MISTRAL_API_KEY=.' "$env_file" 2>/dev/null; }; then
        echo "#[fg=colour114]Mistral"
    else
        echo "#[fg=colour203]Mistral"
    fi
}

ha_status() {
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        echo "#[fg=colour245]HA"
        return
    fi
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 2 \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        "http://supervisor/core/api/" 2>/dev/null)
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "#[fg=colour114]HA"
    else
        echo "#[fg=colour208]HA"
    fi
}

echo "$(auth_status) #[fg=colour245]| $(ha_status) #[fg=colour245]| #[fg=colour252]$(date '+%a %d/%m %H:%M')"
