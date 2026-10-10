# Heal Per Mana

Priest heal-rank list. `/hpm` shows every known heal rank sorted by heal per mana. It does not read `UnitHealth`.

Target client: World of Warcraft **Forever** (`camelot`, TOC `## Interface: 16001`).

## Features

- One row per known heal rank: spell, rank, cast time, mana, heal, and heal per mana.
- Click a column header to sort. Click a row to fill a `/cast Spell(Rank N)` line (Ctrl+C). The addon never opens chat.
- Unlearned ranks can be shown from settings. They stay out of the list by default.
- Addon compartment toggles the list. `/hpm settings` opens the settings panel.

## Commands

| Command | Effect |
| --- | --- |
| `/hpm`, `/healpermana` | Toggle the list |
| `/hpm settings` | Open settings |
| `/hpm debug` | Dump scanned ranks to chat |
| `/hpm help` | List commands |

## Files

Loaded in TOC order; modules communicate only through the shared `ns` table.

| File | Concern |
| --- | --- |
| `Data.lua` | Families and spell IDs |
| `Locales/enUS.lua` | UI strings |
| `Locales.lua` | Locale fallback |
| `Secrets.lua` | Secret-value guards |
| `Database.lua` | SavedVariables defaults, migrations, validation |
| `Parse.lua` | Tooltip and description heal extract |
| `Scanner.lua` | Spellbook scan |
| `Recommender.lua` | Heal per mana and sort |
| `UI.lua` | List window |
| `Events.lua` | Event frame |
| `Options.lua` | Settings panel and slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\HealPerMana" "D:\Repos\Joipov\HealPerMana"
```

Static checks (no game client needed):

```
luacheck .            # .luacheckrc: Lua 5.1, explicit WoW globals
luajit tests/run.lua  # or: lua5.1 tests/run.lua
```

LuaLS uses `.luarc.json` and Ketho's WoW API annotations. The repo-local
`.annotations/` folder declares Blizzard globals those annotations lack.

`assets/` is release media for CurseForge and Wago (screenshots, and a logo
when one exists). The game does not load it, and it is not part of the addon
zip. Do not delete it during cleanup.

Local zip, with the addon folder at the root, written to `.release/`:

```
powershell -File package.ps1
```

Releases: push an annotated tag (`git tag -a 1.1.0 -m "1.1.0"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
`CODE_AUDIT.md` is the audit note and is not shipped.
