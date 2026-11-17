# Changelog

## 0.1.2

- Documentation is now in English
- The add-on options show names and descriptions in the Home Assistant UI (`translations/en.yaml`)

## 0.1.1

- Fixed: installation failed because the `ttyd` package does not exist in Debian trixie. ttyd 1.7.7 is now installed from the official static binary, with a verified SHA256 checksum
- The sign-in link from Mistral Vibe is sent as a clickable Home Assistant notification (the bell icon), since there is no browser inside the add-on
- The web terminal uses ttyd's DOM renderer, because Vibe's full-screen UI was drawn shifted on high-resolution screens and mobile devices
- No more bashio deprecation warnings in the log

## 0.1.0

- First release: Mistral Vibe 3.1.2 in a web terminal (ttyd + tmux) through ingress
- Sign in with a Mistral account (stored in /data) or an optional key in the options
- ha-mcp is registered automatically as the MCP server `home_assistant`
- HA Smart Context writes AGENTS.md with facts about your Home Assistant
- Debian base (Mistral Vibe has no Alpine/musl packages)
