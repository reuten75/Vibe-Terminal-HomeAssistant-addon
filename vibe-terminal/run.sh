#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Vibe Terminal — Mistral Vibe in a browser terminal (ttyd + tmux).
#
# Adapted from Claude Terminal by heytcass
# (https://github.com/heytcass/home-assistant-addons, MIT).
#
# Nothing on the boot path may depend on the network or block on input.
# Network work (Vibe updates, HA context, ha-mcp pre-warm) runs in the
# background after the terminal is already available.

set -e
set -o pipefail

SESSION_NAME="vibe"

init_environment() {
    local data_home="/data/home"

    bashio::log.info "Initializing Vibe environment in /data..."

    if ! mkdir -p "$data_home/.local/bin" "/data/.config" "/data/.cache" \
        "/data/.local/state" "/data/.local/share" "/data/vibe"; then
        bashio::log.error "Failed to create directories in /data"
        exit 1
    fi
    chmod 700 /data/vibe

    export HOME="$data_home"
    export XDG_CONFIG_HOME="/data/.config"
    export XDG_CACHE_HOME="/data/.cache"
    export XDG_STATE_HOME="/data/.local/state"
    export XDG_DATA_HOME="/data/.local/share"

    # All Vibe state (config.toml, .env with the sign-in key, sessions,
    # AGENTS.md, trusted folders) lives here and persists across restarts.
    export VIBE_HOME="/data/vibe"

    # Persistent, auto-updated Vibe (see update_vibe) wins over the bundled one
    export PATH="$data_home/.local/bin:$PATH"

    if [ -f /opt/scripts/tmux.conf ]; then
        cp /opt/scripts/tmux.conf "$data_home/.tmux.conf"
        chmod 644 "$data_home/.tmux.conf"
    fi

    bashio::log.info "Environment initialized (HOME=${HOME}, VIBE_HOME=${VIBE_HOME})"
}

setup_commands() {
    local entry name script
    for entry in \
        "welcome:/opt/scripts/welcome.sh" \
        "ha-context:/opt/scripts/ha-context.sh" \
        "ha-mcp-launch:/opt/scripts/ha-mcp-launch.sh" \
        "persist-install:/opt/scripts/persist-install.sh" \
        "xdg-open:/opt/scripts/xdg-open.sh"; do
        name="${entry%%:*}"
        script="${entry#*:}"
        if [ -f "$script" ]; then
            cp "$script" "/usr/local/bin/$name"
            chmod +x "/usr/local/bin/$name"
        else
            bashio::log.warning "Script not found: $script"
        fi
    done

    bashio::app.version > /opt/scripts/addon-version 2>/dev/null \
        || echo "unknown" > /opt/scripts/addon-version
}

# A persistent install that exists but fails to start must never shadow the
# working bundled copy on PATH (the tmux session would die with it).
persistent_vibe_runs() {
    timeout 20 "$HOME/.local/bin/vibe" --version >/dev/null 2>&1
}

remove_persistent_vibe() {
    rm -f "$HOME/.local/bin/vibe" "$HOME/.local/bin/vibe-acp"
}

update_vibe() {
    local persistent_ok=false
    if [ -x "$HOME/.local/bin/vibe" ]; then
        if persistent_vibe_runs; then
            persistent_ok=true
        else
            bashio::log.warning "Persistent Vibe is present but fails to run; falling back to the bundled copy"
            remove_persistent_vibe
        fi
    fi

    if [ "$(bashio::config 'vibe_auto_update' 'true')" != "true" ]; then
        if [ "$persistent_ok" = true ]; then
            bashio::log.info "Vibe auto-update disabled; using persistent Vibe"
        else
            bashio::log.info "Vibe auto-update disabled; using bundled Vibe ($(vibe --version 2>/dev/null || echo 'version unknown'))"
        fi
        return 0
    fi

    bashio::log.info "Checking for Mistral Vibe updates in the background"
    (
        if UV_TOOL_DIR=/data/uv-tools UV_TOOL_BIN_DIR="$HOME/.local/bin" \
            timeout 600 uv tool install --upgrade --python /usr/bin/python3 mistral-vibe \
            </dev/null >/dev/null 2>&1 && persistent_vibe_runs; then
            bashio::log.info "Persistent Mistral Vibe ready: $("$HOME/.local/bin/vibe" --version 2>/dev/null || echo 'version unknown')"
        else
            if [ -x "$HOME/.local/bin/vibe" ] && ! persistent_vibe_runs; then
                remove_persistent_vibe
            fi
            bashio::log.warning "Could not install/update persistent Vibe; using the copy that already works"
        fi
    ) &
}

install_persistent_packages() {
    local persist_config="/data/persistent-packages.json"
    local apt_packages="" pip_packages="" value

    if bashio::config.has_value 'persistent_apt_packages'; then
        value=$(bashio::config 'persistent_apt_packages') || value=""
        [ "$value" != "null" ] && apt_packages="$value"
    fi
    if bashio::config.has_value 'persistent_pip_packages'; then
        value=$(bashio::config 'persistent_pip_packages') || value=""
        [ "$value" != "null" ] && pip_packages="$value"
    fi
    if [ -f "$persist_config" ]; then
        apt_packages="$apt_packages $(jq -r '(.apt_packages // []) | join(" ")' "$persist_config" 2>/dev/null || true)"
        pip_packages="$pip_packages $(jq -r '(.pip_packages // []) | join(" ")' "$persist_config" 2>/dev/null || true)"
    fi

    apt_packages=$(echo "$apt_packages" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ' | xargs)
    pip_packages=$(echo "$pip_packages" | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ' ' | xargs)

    [ -z "$apt_packages" ] && [ -z "$pip_packages" ] && return 0

    # Needs the network: run in the background so the terminal comes up first
    bashio::log.info "Installing persistent packages in background (apt: ${apt_packages:-none}; pip: ${pip_packages:-none})"
    (
        if [ -n "$apt_packages" ]; then
            # shellcheck disable=SC2086
            if apt-get update >/dev/null 2>&1 \
                && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $apt_packages >/dev/null 2>&1; then
                bashio::log.info "apt packages installed: $apt_packages"
            else
                bashio::log.warning "Some apt packages failed to install: $apt_packages"
            fi
        fi
        if [ -n "$pip_packages" ]; then
            # shellcheck disable=SC2086
            if pip3 install --break-system-packages --no-cache-dir $pip_packages >/dev/null 2>&1; then
                bashio::log.info "pip packages installed: $pip_packages"
            else
                bashio::log.warning "Some pip packages failed to install: $pip_packages"
            fi
        fi
    ) &
}

generate_ha_context() {
    if [ "$(bashio::config 'ha_smart_context' 'true')" != "true" ]; then
        bashio::log.info "HA Smart Context disabled in configuration"
        return 0
    fi
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.info "No Supervisor: skipping HA Smart Context"
        return 0
    fi
    bashio::log.info "Generating Home Assistant context (AGENTS.md) in background"
    (/usr/local/bin/ha-context >/dev/null 2>&1 || true) &
}

# Optional key from the add-on configuration. It reaches the auto-launched
# vibe via the environment (tmux inherits run.sh's). Vibe then reports the
# key as coming from the process environment. The value is never logged.
export_mistral_api_key() {
    local key
    key=$(bashio::config 'mistral_api_key' '') || key=""
    if [ -n "$key" ] && [ "$key" != "null" ]; then
        export MISTRAL_API_KEY="$key"
        bashio::log.info "MISTRAL_API_KEY set from add-on configuration"
    elif [ -f "$VIBE_HOME/.env" ] && grep -q '^MISTRAL_API_KEY=' "$VIBE_HOME/.env" 2>/dev/null; then
        bashio::log.info "Using the Mistral key saved by 'Sign in with Mistral' (${VIBE_HOME}/.env)"
    else
        bashio::log.info "Not signed in yet: open the terminal and choose 'Launch browser' (the link arrives as an HA notification)"
    fi
}

build_vibe_flags() {
    local flags=""

    if [ "$(bashio::config 'auto_approve' 'false')" = "true" ]; then
        flags="--auto-approve"
    fi

    local extra
    extra=$(bashio::config 'vibe_extra_args' '') || extra=""
    if [ -n "$extra" ] && [ "$extra" != "null" ]; then
        flags="${flags:+$flags }$extra"
    fi

    echo "$flags"
}

get_working_directory() {
    local dir
    dir=$(bashio::config 'working_directory' '') || dir=""
    if [ -z "$dir" ] || [ "$dir" = "null" ]; then
        echo "/config"
        return 0
    fi
    if [ -d "$dir" ]; then
        echo "$dir"
    else
        bashio::log.warning "working_directory '$dir' does not exist; starting in /config instead"
        echo "/config"
    fi
}

# The command tmux runs inside the session (parsed once by tmux's shell, so
# quoting in vibe_extra_args works). When vibe exits, drop to a shell
# instead of killing the session.
get_session_command() {
    local flags="$1"
    if [ "$(bashio::config 'auto_launch_vibe' 'true')" = "true" ]; then
        echo "vibe${flags:+ $flags}; /usr/local/bin/welcome --shell"
    else
        echo "/usr/local/bin/welcome --shell"
    fi
}

# Start the tmux session at boot so ttyd's `new-session -A` just attaches.
start_session_now() {
    local workdir=$1 session_command=$2
    [ "$(bashio::config 'auto_launch_vibe' 'true')" = "true" ] || return 0
    if TERM=xterm-256color tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50 -c "$workdir" "$session_command"; then
        bashio::log.info "Vibe started in the background; the web terminal attaches to it"
    else
        bashio::log.warning "Could not pre-start the tmux session; it will start on the first terminal visit"
    fi
}

# nginx in front of ttyd: only the Supervisor's ingress proxy (and loopback)
# can reach the terminal. Opened to all clients only when 7681 is published
# on the host, or when there is no Supervisor (local test runs).
start_ingress_proxy() {
    local open_gate=/run/vibe-terminal/allow-any-client.conf
    rm -f "$open_gate"

    local allow_all=false host_port=""
    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        allow_all=true
        bashio::log.info "No Supervisor: web terminal reachable from any address (local test run)"
    else
        host_port=$(bashio::app.port 7681/tcp 2>/dev/null) || host_port=""
        if [[ "$host_port" =~ ^[0-9]+$ ]]; then
            allow_all=true
            bashio::log.warning "Port 7681 is published on the host (${host_port}): anyone who can reach it gets a root shell with no login"
        fi
    fi

    if [ "$allow_all" = true ]; then
        mkdir -p "$(dirname "$open_gate")"
        echo 'allow all;' > "$open_gate"
    fi

    nginx -c /opt/scripts/nginx.conf \
        || bashio::exit.nok "nginx failed to start; the web terminal would be unreachable"
}

setup_ha_mcp() {
    if [ -f /opt/scripts/setup-ha-mcp.sh ]; then
        # shellcheck source=/dev/null
        source /opt/scripts/setup-ha-mcp.sh
        configure_ha_mcp_server || bashio::log.warning "ha-mcp setup encountered issues but continuing..."
    fi
}

start_web_terminal() {
    local port=7682
    local flags session_command workdir
    flags=$(build_vibe_flags)

    if [[ "$flags" == *"--auto-approve"* ]] || [[ "$flags" == *"--yolo"* ]]; then
        bashio::log.warning "=========================================================="
        bashio::log.warning "auto_approve is ENABLED."
        bashio::log.warning "Vibe will run every tool without asking for confirmation."
        bashio::log.warning "It has write access to /config and can control Home"
        bashio::log.warning "Assistant through the Supervisor API and MCP."
        bashio::log.warning "=========================================================="
    fi

    session_command=$(get_session_command "$flags")
    workdir=$(get_working_directory)

    bashio::log.info "Starting web terminal on loopback port ${port}, served on 7681 via nginx"

    # rendererType=dom: in testing, ttyd's canvas/WebGL renderers drew
    # Vibe's full-screen UI scaled and shifted at device pixel ratio 2
    # (HiDPI/phones), while the DOM renderer drew it correctly.
    #
    # Dark palette with Mistral orange accents
    local ttyd_theme='{"background":"#1a1b26","foreground":"#c0caf5","cursor":"#fa500f","cursorAccent":"#1a1b26","selectionBackground":"#33467c","selectionForeground":"#c0caf5","black":"#15161e","red":"#f7768e","green":"#9ece6a","yellow":"#e0af68","blue":"#7aa2f7","magenta":"#bb9af7","cyan":"#7dcfff","white":"#a9b1d6","brightBlack":"#414868","brightRed":"#f7768e","brightGreen":"#9ece6a","brightYellow":"#e0af68","brightBlue":"#7aa2f7","brightMagenta":"#bb9af7","brightCyan":"#7dcfff","brightWhite":"#c0caf5"}'

    start_session_now "$workdir" "$session_command"

    local index_args=()
    if [ -f /opt/ttyd/index.html ]; then
        index_args=(--index /opt/ttyd/index.html)
    else
        bashio::log.warning "Patched terminal page missing; serving ttyd's stock page"
    fi

    exec ttyd \
        --port "${port}" \
        --interface lo \
        --writable \
        --ping-interval 30 \
        --client-option enableReconnect=true \
        --client-option reconnect=10 \
        --client-option reconnectInterval=5 \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        --client-option rendererType=dom \
        --client-option macOptionClickForcesSelection=true \
        "${index_args[@]}" \
        tmux new-session -A -s "$SESSION_NAME" -c "$workdir" "$session_command"
}

main() {
    bashio::log.info "Starting Vibe Terminal add-on..."

    init_environment
    export_mistral_api_key
    setup_commands
    update_vibe
    install_persistent_packages
    generate_ha_context
    setup_ha_mcp
    start_ingress_proxy
    start_web_terminal
}

main "$@"
