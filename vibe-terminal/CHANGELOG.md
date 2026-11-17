# Changelog

## 0.1.1

- Rättat: installationen misslyckades eftersom paketet `ttyd` inte finns i Debian trixie. ttyd 1.7.7 hämtas nu som officiell statisk binärfil med kontrollerad SHA256-checksumma
- Inloggningslänken från "Sign in with Mistral" skickas som en klickbar notis i Home Assistant (klockikonen), eftersom det inte finns någon webbläsare i add-onet
- Webbterminalen använder ttyds DOM-renderare, eftersom Vibes helskärmsvy ritades förskjuten på skärmar med hög upplösning och på mobiler
- Inga utfasningsvarningar från bashio i loggen längre

## 0.1.0

- Första versionen: Mistral Vibe 3.1.2 i en webbterminal (ttyd + tmux) via ingress
- Inloggning med Mistral-konto (sparas i /data) eller valfri nyckel i inställningarna
- ha-mcp registreras automatiskt som MCP-server `home_assistant`
- HA Smart Context skriver AGENTS.md med fakta om din Home Assistant
- Debian-bas (Mistral Vibe saknar Alpine/musl-paket)
