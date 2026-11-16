#!/bin/bash

# Vibe Terminal banner. With --shell, drops into an interactive bash
# afterwards (shell mode, or after vibe exits).

ORANGE='\033[38;2;250;80;15m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

version=$(cat /opt/scripts/addon-version 2>/dev/null || echo "unknown")

echo ""
echo -e "  ${ORANGE}Vibe Terminal${NC}  ${DIM}v${version} · Home Assistant add-on${NC}"
echo ""
echo -e "  ${WHITE}vibe${NC}              start Mistral Vibe  ${DIM}(--continue · --resume)${NC}"
echo -e "  ${WHITE}ha-context${NC}        refresh the Home Assistant context (AGENTS.md) for Vibe"
echo -e "  ${WHITE}persist-install${NC}   install apt/pip packages that survive restarts"
echo ""
echo -e "  ${DIM}Copy: drag to select (Shift+drag, Option on Mac, if the browser blocks it) · Paste: Ctrl+Shift+V${NC}"
echo -e "  ${DIM}New line in Vibe's prompt: Shift+Enter or Ctrl+J${NC}"
echo ""

if [ "${1:-}" = "--shell" ]; then
    exec bash
fi
