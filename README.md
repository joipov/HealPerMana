# Heal Per Mana Table

Heal-rank list for every class. `/hpm` shows each mana heal and absorb sorted by heal per mana. It does not read `UnitHealth`.

Target client: World of Warcraft **Forever**, release client (`_forever_`, `## Interface: 16001`). The old Forever beta (`_classic_beta_`) uses the same TOC and game type.

## Features

- One row per heal rank: spell, rank, cast time, mana, heal, and heal per mana. Learned spells come from the spellbook, on any class.
- A row is a spell whose tooltip states a heal or an absorb and whose cost is mana. Party heals stay one target. A stated bolt count, jump count, or chain falloff is added in.
- Click a column header to sort. Click a row to fill a `/cast` macro for that rank (Ctrl+C). The addon never opens chat.
- Unlearned ranks can be shown from settings, for the class you are logged in as. They stay out of the list by default.
- The addon compartment, the minimap button, and `/hpm settings` open settings. `/hpm` toggles the list.

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
| `Data.lua` | Class spell IDs |
| `Locales/enUS.lua` | UI strings |
| `Secrets.lua` | Secret-value guards, chat |
| `Database.lua` | SavedVariables defaults, migrations, validation |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button, addon compartment |
| `Parse.lua` | Tooltip and description heal extract |
| `Scanner.lua` | Spellbook scan |
| `Recommender.lua` | Heal per mana and sort |
| `UI.lua` | List window |
| `Events.lua` | Event frame |
| `Options.lua` | Settings panel, slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\HealPerMana" "D:\Repos\Joipov\HealPerMana"
```

The same link works under `_classic_beta_` if the old beta client is still installed.

Static checks (no game client needed):

```
luacheck .            # .luacheckrc: Lua 5.1, explicit WoW globals
luajit tests/run.lua  # or: lua5.1 tests/run.lua
```

LuaLS uses `.luarc.json` and Ketho's WoW API annotations. The repo-local
`.annotations/` folder declares the Forever secret-value helpers those
annotations lack.

`assets/` is release media for CurseForge and Wago (screenshots, and a logo
when one exists). The game does not load it, and it is not part of the addon
zip. Do not delete it during cleanup.

Local zip, with the addon folder at the root, written to `.release/`:

```
powershell -File package.ps1
```

Releases: push an annotated tag (`git tag -a 1.2.0 -m "1.2.0"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
The audit note is not shipped.
