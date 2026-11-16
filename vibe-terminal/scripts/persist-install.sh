#!/bin/bash
#
# persist-install — install packages now and reinstall them on every start.
# (Idea from Claude Terminal's persist-install, rewritten for Debian/apt.)
#
#   persist-install apt <pkg> [pkg...]
#   persist-install pip <pkg> [pkg...]
#   persist-install remove apt|pip <pkg>
#   persist-install list

set -euo pipefail

PERSIST_CONFIG="/data/persistent-packages.json"

init_config() {
    [ -f "$PERSIST_CONFIG" ] || echo '{"apt_packages": [], "pip_packages": []}' > "$PERSIST_CONFIG"
}

add_to_config() {
    local key="$1"; shift
    local pkg tmp
    for pkg in "$@"; do
        tmp=$(mktemp)
        jq --arg k "$key" --arg p "$pkg" '.[$k] = ((.[$k] // []) + [$p] | unique)' "$PERSIST_CONFIG" > "$tmp"
        mv "$tmp" "$PERSIST_CONFIG"
    done
}

usage() {
    cat <<'EOF'
persist-install - install packages that survive add-on restarts

  persist-install apt <pkg> [pkg...]     install Debian packages
  persist-install pip <pkg> [pkg...]     install Python packages
  persist-install remove apt|pip <pkg>   stop reinstalling a package
  persist-install list                   show persistent packages
EOF
}

init_config

case "${1:-help}" in
    apt)
        shift
        [ $# -gt 0 ] || { usage; exit 1; }
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
        add_to_config apt_packages "$@"
        echo "Saved: $* (reinstalled on every start)"
        ;;
    pip)
        shift
        [ $# -gt 0 ] || { usage; exit 1; }
        pip3 install --break-system-packages --no-cache-dir "$@"
        add_to_config pip_packages "$@"
        echo "Saved: $* (reinstalled on every start)"
        ;;
    remove)
        [ $# -eq 3 ] || { usage; exit 1; }
        case "$2" in apt|pip) ;; *) usage; exit 1 ;; esac
        tmp=$(mktemp)
        jq --arg k "${2}_packages" --arg p "$3" '.[$k] = ((.[$k] // []) - [$p])' "$PERSIST_CONFIG" > "$tmp"
        mv "$tmp" "$PERSIST_CONFIG"
        echo "Removed $3 from persistent $2 packages (still installed until restart)"
        ;;
    list)
        echo "apt: $(jq -r '(.apt_packages // []) | join(" ")' "$PERSIST_CONFIG")"
        echo "pip: $(jq -r '(.pip_packages // []) | join(" ")' "$PERSIST_CONFIG")"
        ;;
    *)
        usage
        ;;
esac
