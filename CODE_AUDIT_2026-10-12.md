# Heal Per Mana Table audit — 2026-10-12

Target: World of Warcraft Forever, `## Interface: 16001`, Lua 5.1.
References: Ketho's vscode-wow-api annotations, the Forever API, and the other Joipov addons.

## Already in good shape

Heal text parsing and secret checks from the 2026-10-11 pass still hold. Spellbook events and the unlearned setting already call `ns.InvalidateCache`.

## This pass

- `ns.GetSpells()` returns the last scan until that cache is cleared.
- The minimap button is the shared launcher. Click still opens settings.
- The 1.2.2 login-line change is in the changelog. The spell cache is 1.2.3.
- TOC fields follow the house order.
- Ketho's annotation path stays in `.luarc.json`. That file is the library list LuaLS uses for this addon.

## Left as-is

Raw spellbook compares that the client can hide stay as they were. The scan still guards values it indexes.
