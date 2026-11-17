# Vibe Terminal

Mistral Vibe in a web terminal (ttyd + tmux) as a Home Assistant add-on, with your Home Assistant configuration mounted and full access to Home Assistant through ha-mcp.

## Getting started

1. Start the add-on and open **Vibe Terminal** from the sidebar.
2. Vibe starts automatically in `/config`. The first time:
   - choose **Launch browser → Mistral AI**. There is no browser inside the add-on, so the link appears as a **Home Assistant notification** instead (the bell icon in the sidebar). Click **Open link**, sign in with your Mistral account and go back to Vibe Terminal, where Vibe continues automatically. You can also use the copy key that Vibe shows to copy the link.
   - allow Vibe to work in the `/config` folder (asked once per folder).
3. Ask Vibe for what you need, for example *"Create an automation that turns on the hallway light at sunset"* or *"Why doesn't my heat pump automation trigger?"*.

The sign-in is stored as `MISTRAL_API_KEY` in `/data/vibe/.env` and survives restarts and updates. The file is included in Home Assistant backups.

## Options

| Option | Default | Description |
|---|---|---|
| `auto_launch_vibe` | `true` | Start Vibe as soon as the terminal opens. `false` gives you a shell where you run `vibe` yourself. |
| `vibe_auto_update` | `true` | Installs and updates Mistral Vibe in `/data` in the background on every start. The image ships version 3.1.2 as a fallback. |
| `working_directory` | `""` | Folder to start in (default `/config`). |
| `mistral_api_key` | `""` | Optional key instead of the account sign-in. When set, it is used before the saved sign-in. It is masked in the UI but included in backups. |
| `auto_approve` | `false` | Starts Vibe with `--auto-approve`, so every tool call runs without asking. **See the security section below.** |
| `vibe_extra_args` | `""` | Extra flags for `vibe`, for example `--agent plan`. Quoting works as in a shell. |
| `ha_smart_context` | `true` | Writes `/data/vibe/AGENTS.md` with facts about your Home Assistant (version, entities per domain, add-ons, recent errors). Vibe reads it in every session. Run `ha-context` to refresh it, or `ha-context --full` to also list entity IDs. |
| `enable_ha_mcp` | `true` | Registers ha-mcp as the MCP server `home_assistant` in Vibe's `config.toml`. With `false`, the entry is removed. |
| `ha_mcp_version` | `"7.11.0"` | The ha-mcp version to run. |
| `persistent_apt_packages` | `[]` | Debian packages installed on every start. |
| `persistent_pip_packages` | `[]` | Python packages installed on every start. |

## Commands in the terminal

```bash
vibe              # start Vibe
vibe --continue   # continue the most recent conversation
vibe --resume     # pick an earlier conversation
ha-context        # refresh the Home Assistant context (AGENTS.md)
persist-install apt htop        # install packages that survive restarts
persist-install pip pandas
```

If you exit Vibe, you get a shell in the same tmux session.

### Terminal tips

- **New line in Vibe's prompt:** Shift+Enter or Ctrl+J.
- **Copy:** drag with the mouse. If the browser blocks clipboard access (common with Home Assistant over plain HTTP), hold Shift (Option on Mac) while dragging.
- **Paste:** Ctrl+Shift+V.
- **Your own tmux settings:** put them in `/data/home/.tmux.local.conf`.

## How Vibe accesses Home Assistant

- **Files:** `/config` (the Home Assistant configuration), `/addon_configs` and `/share` are mounted read-write.
- **ha-mcp:** Vibe starts `/usr/local/bin/ha-mcp-launch`, which runs ha-mcp against the Supervisor API. The Supervisor token is read only when the server starts and is never stored in `config.toml`. ha-mcp runs on Debian's Python 3.13, and its dependencies are fetched in the background at startup.
- **API:** `SUPERVISOR_TOKEN` is available in the terminal environment, so Vibe can also use `curl` against `http://supervisor/core/api/...`.

Your own MCP servers and other settings in `/data/vibe/config.toml` are left untouched. The add-on only manages the `home_assistant` entry.

## Security

This add-on deliberately gives Vibe a lot of power. It runs as root in its container, has write access to `/config`, and can control devices and change automations through ha-mcp.

- **`auto_approve` removes the last human checkpoint.** A misunderstanding, or a prompt injection in a file or web page that Vibe reads, can then change your configuration or control devices without asking you. Leave it off unless you knowingly accept that risk.
- The web terminal is only reachable through Home Assistant ingress. Port 7681 is not published by default. If you publish it, anyone who can reach the port gets a root shell without logging in.
- Mistral Vibe sends telemetry by default. Add `enable_telemetry = false` to `/data/vibe/config.toml` to turn it off.

## Troubleshooting

- **Vibe asks you to sign in again:** check that `/data/vibe/.env` exists with `ls -la /data/vibe` in the shell.
- **ha-mcp tools are missing:** look for `ha-mcp ... registered` in the add-on log. Test the server by hand with `ha-mcp-launch 7.11.0 --prewarm` (it should exit without errors). Then type `/mcp` in Vibe.
- **The build fails:** the add-on is built locally and needs internet access for Debian packages, PyPI and Mistral Vibe. The full build log is under **Settings → System → Logs**, with **Supervisor** selected in the top-right list.
