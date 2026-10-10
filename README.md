# Heal Per Mana

Priest heal-rank list for World of Warcraft **Forever** (`camelot`, TOC `## Interface: 16001`).

`/hpm` shows every known heal rank sorted by **heal per mana**. It does not read `UnitHealth`.

## Commands

| Command | Effect |
| --- | --- |
| `/hpm` | Toggle the list |
| `/hpm settings` | Open settings |
| `/hpm debug` | Dump scanned ranks to chat |
| `/hpm help` | List commands |

Click a column header to sort. Click a row to fill the `/cast Spell(Rank N)` line (Ctrl+C). The addon never opens chat.

## Files

| File | Concern |
| --- | --- |
| `Data.lua` | Families and catalog fallbacks |
| `Locales/enUS.lua` | UI strings |
| `Secrets.lua` | Secret-value guards |
| `Database.lua` | SavedVariables |
| `Parse.lua` | Tooltip/description heal extract |
| `Scanner.lua` | Spellbook scan |
| `Recommender.lua` | HPM and sort |
| `UI.lua` | List window |
| `Events.lua` | Event frame |
| `Options.lua` | Settings and slash commands |
