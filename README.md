# Vibe Terminal för Home Assistant

Ett Home Assistant-add-on som kör [Mistral Vibe](https://github.com/mistralai/mistral-vibe) i en webbterminal direkt i HA:s sidomeny. Vibe kan läsa och ändra din konfiguration i `/config` och styra Home Assistant via [ha-mcp](https://github.com/homeassistant-ai/ha-mcp), så att den kan skriva automationer, felsöka och mycket mer.

Bygger på [Claude Terminal](https://github.com/heytcass/home-assistant-addons) av heytcass (MIT) men använder Mistral Vibe i stället för Claude Code.

## Installation

1. I Home Assistant: **Inställningar → Tillägg (Apps) → Tilläggsbutik**
2. Menyn med tre punkter uppe till höger → **Repositories**
3. Lägg till `https://github.com/reuten75/vibe-terminal-homeassistant-addon`
4. Installera **Vibe Terminal** och starta det. Första bygget sker lokalt på din HA och tar några minuter.
5. Öppna **Vibe Terminal** i sidomenyn och välj **Sign in with Mistral**

Se [vibe-terminal/DOCS.md](vibe-terminal/DOCS.md) för inställningar och detaljer.
