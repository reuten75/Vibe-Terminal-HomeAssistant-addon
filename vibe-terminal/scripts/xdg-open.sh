#!/bin/bash
#
# xdg-open replacement for the add-on container (there is no browser here).
#
# Mistral Vibe opens its sign-in page with `xdg-open URL`. Instead of failing,
# post the link as a persistent Home Assistant notification, so it can be
# opened with one click from the bell icon in the HA sidebar. Only http(s)
# links are accepted. Nothing is printed: Vibe's full-screen UI owns the
# terminal.

url="${1:-}"
case "$url" in
    https://*|http://*) ;;
    *) exit 1 ;;
esac

token="${SUPERVISOR_TOKEN:-}"
if [ -z "$token" ] && [ -r /run/s6/container_environment/SUPERVISOR_TOKEN ]; then
    token=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN)
fi
[ -n "$token" ] || exit 1

payload=$(jq -n --arg url "$url" '{
    notification_id: "vibe_terminal_open_link",
    title: "Vibe Terminal",
    message: ("Mistral Vibe wants to open a link (for example to sign in):\n\n[Open link](" + $url + ")\n\nAfter signing in, go back to Vibe Terminal: it continues automatically.")
}')

curl -fsS -m 10 -o /dev/null -X POST \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "http://supervisor/core/api/services/persistent_notification/create"
