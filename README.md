# Vibe Terminal for Home Assistant

A Home Assistant add-on that runs [Mistral Vibe](https://github.com/mistralai/mistral-vibe) in a web terminal, right in the Home Assistant sidebar. Vibe can read and edit your configuration in `/config` and control Home Assistant through [ha-mcp](https://github.com/homeassistant-ai/ha-mcp), so it can write automations, troubleshoot problems and much more.

Based on [Claude Terminal](https://github.com/heytcass/home-assistant-addons) by heytcass (MIT), with Mistral Vibe instead of Claude Code.

## Installation

1. In Home Assistant, go to **Settings → Add-ons (Apps) → Add-on Store**
2. Open the three-dot menu in the top-right corner → **Repositories**
3. Add `https://github.com/reuten75/vibe-terminal-homeassistant-addon`
4. Install **Vibe Terminal** and start it. The first build runs locally on your Home Assistant and takes several minutes.
5. Open **Vibe Terminal** from the sidebar and choose **Launch browser → Mistral AI**. The sign-in link arrives as a Home Assistant notification (the bell icon).

Supported architectures: `amd64` and `aarch64` (for example Raspberry Pi 4/5, ODROID-N2, Home Assistant Green/Yellow).

See [vibe-terminal/DOCS.md](vibe-terminal/DOCS.md) for options and details.

## License

MIT, see [LICENSE](LICENSE).
