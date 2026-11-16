# Vibe Terminal

Mistral Vibe i en webbterminal (ttyd + tmux) som Home Assistant-add-on, med din HA-konfiguration monterad och full åtkomst till Home Assistant via ha-mcp.

## Kom igång

1. Starta add-onet och öppna **Vibe Terminal** i sidomenyn.
2. Vibe startar automatiskt i `/config`. Första gången:
   - välj **Sign in with Mistral**. Vibe visar en inloggningslänk. Kopiera den (tangenten som visas i Vibe, eller markera med musen) och öppna den i valfri webbläsare. Logga in med ditt Mistral-konto, så fortsätter Vibe automatiskt när inloggningen är klar.
   - godkänn att Vibe får arbeta i mappen `/config` (en gång per mapp).
3. Be Vibe om det du vill, till exempel *"Skapa en automation som tänder hallen vid solnedgång"* eller *"Varför startar inte min automation för värmepumpen?"*.

Inloggningen sparas som `MISTRAL_API_KEY` i `/data/vibe/.env` och finns kvar efter omstarter och uppdateringar. Filen ingår i Home Assistants säkerhetskopior.

## Inställningar

| Inställning | Standard | Beskrivning |
|---|---|---|
| `auto_launch_vibe` | `true` | Starta Vibe direkt när terminalen öppnas. `false` ger ett skal där du kör `vibe` själv. |
| `vibe_auto_update` | `true` | Installerar och uppdaterar Mistral Vibe i `/data` i bakgrunden vid varje start. Versionen i imagen är 3.1.2 och används som reserv. |
| `working_directory` | `""` | Mapp att starta i (standard `/config`). |
| `mistral_api_key` | `""` | Valfri nyckel i stället för kontoinloggningen. Om fältet är ifyllt används nyckeln före den sparade inloggningen. Den maskeras i gränssnittet men ingår i säkerhetskopior. |
| `auto_approve` | `false` | Startar Vibe med `--auto-approve`, så att alla verktygsanrop körs utan fråga. **Se säkerhetsavsnittet nedan.** |
| `vibe_extra_args` | `""` | Extra flaggor till `vibe`, t.ex. `--agent plan`. Citattecken fungerar som i ett skal. |
| `ha_smart_context` | `true` | Skriver `/data/vibe/AGENTS.md` med fakta om din HA (version, entiteter per domän, add-ons, senaste fel). Vibe läser filen i varje session. Kör `ha-context` för att uppdatera den, eller `ha-context --full` för att även lista entitets-ID:n. |
| `enable_ha_mcp` | `true` | Registrerar ha-mcp som MCP-server `home_assistant` i Vibes `config.toml`. Med `false` tas posten bort. |
| `ha_mcp_version` | `"7.11.0"` | Vilken version av ha-mcp som körs. |
| `persistent_apt_packages` | `[]` | Debian-paket som installeras vid varje start. |
| `persistent_pip_packages` | `[]` | Python-paket som installeras vid varje start. |

## Kommandon i terminalen

```bash
vibe              # starta Vibe
vibe --continue   # fortsätt senaste konversationen
vibe --resume     # välj en tidigare konversation
ha-context        # uppdatera HA-kontexten (AGENTS.md)
persist-install apt htop        # installera paket som överlever omstarter
persist-install pip pandas
```

Om du avslutar Vibe hamnar du i ett skal i samma tmux-session.

### Terminaltips

- **Ny rad i Vibes prompt:** Shift+Enter eller Ctrl+J.
- **Kopiera:** dra med musen. Om webbläsaren blockerar urklipp (vanligt med HA över vanlig HTTP), håll Shift (Option på Mac) medan du drar.
- **Klistra in:** Ctrl+Shift+V.
- **Egna tmux-inställningar:** lägg dem i `/data/home/.tmux.local.conf`.

## Så får Vibe tillgång till Home Assistant

- **Filer:** `/config` (HA-konfigurationen), `/addon_configs` och `/share` är monterade med läs- och skrivrätt.
- **ha-mcp:** Vibe startar `/usr/local/bin/ha-mcp-launch`, som kör ha-mcp mot Supervisor-API:t. Supervisor-token läses först när servern startar och sparas aldrig i `config.toml`. ha-mcp körs på Debians Python 3.13, och beroendena hämtas i bakgrunden vid start.
- **API:** `SUPERVISOR_TOKEN` finns i terminalens miljö, så Vibe kan även använda `curl` mot `http://supervisor/core/api/...`.

Dina egna MCP-servrar och övriga inställningar i `/data/vibe/config.toml` lämnas orörda. Add-onet ändrar bara posten `home_assistant`.

## Säkerhet

Add-onet ger Vibe stor makt med avsikt. Det kör som root i sin container, har skrivrätt till `/config` och kan styra enheter och ändra automationer via ha-mcp.

- **`auto_approve` tar bort den sista mänskliga kontrollen.** Ett missförstånd, eller en promptinjektion i en fil eller webbsida som Vibe läser, kan då ändra konfigurationen eller styra enheter utan att du tillfrågas. Låt den vara avstängd om du inte medvetet accepterar risken.
- Webbterminalen nås bara via Home Assistants ingress. Port 7681 är inte publicerad som standard. Om du publicerar den kan vem som helst som når porten få ett root-skal utan inloggning.
- Mistral Vibe skickar telemetri som standard. Lägg till `enable_telemetry = false` i `/data/vibe/config.toml` för att stänga av den.

## Felsökning

- **Vibe frågar om inloggning igen:** kontrollera att `/data/vibe/.env` finns, med `ls -la /data/vibe` i skalet.
- **ha-mcp-verktyg saknas:** kontrollera add-on-loggen efter `ha-mcp ... registered`. Testa servern för hand med `ha-mcp-launch 7.11.0 --prewarm` (det ska avslutas utan fel). Skriv sedan `/mcp` i Vibe.
- **Bygget misslyckas:** add-onet byggs lokalt och behöver internet för Debian-paket, PyPI och Mistral Vibe.
