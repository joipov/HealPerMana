# Heal Per Mana Table audit — 2026-10-11

Target: World of Warcraft Forever, game type `forever` (was `camelot`), `## Interface: 16001`, Lua 5.1.
References: the Atraeau Forever API dump (build 70170), Warcraft Wiki (Patch 1.60.1 API changes, Patch 12.0.0 secret values), Ketho's vscode-wow-api annotations, the sibling Joipov addons.

Scope: every `.lua`, the `.toc`, `tests/run.lua`, and the docs. `assets/` and `.release/` are not addon code.

## Findings and what was done

### B1 — Holy Nova showed its damage, not its heal
`Parse.lua` took the first "N to N" range, which Holy Nova names before its group heal. **Fixed** — a group-heal range is matched first when the text says "healing ... for N to N".

### B2 — Power Word: Shield never parsed
The absorb pattern `[Aa]bsorbs?` required a space right after "absorb". **Fixed** — `[Aa]bsorb%a*%s+(%d+)`.

### B3 — Renew never parsed
Renew reads "... of 45 damage over 15 sec", so `(%d+)%s+over` missed it. **Fixed** — `(%d+)%D-over%s+(%d+)`.

### B4 — Thousands separators
Large numbers may be grouped ("1,966"). **Not changed** — it depends on the client's number formatting and needs an in-game check; the checklist below covers it.

### B5 — KnownInBook counted overrides
`IsSpellInSpellBook(id, bank, true)` can report an override as known. **Reviewed, low risk** — left as-is; the ranks it feeds are cross-checked against the catalog.

### B6 — No secret guards on spellbook values
`Scanner.lua` compares and indexes raw spellbook values. **Not changed** — the values are readable on the current client; `Secrets.lua` guards cover the tooltip path. Revisit if the client starts hiding spellbook data.

### B7 — Enable setting scope
The tooltip describes the list. **Reviewed** — the setting hides the window; `/hpm` re-enables it by design.

### CQ-001 — Minimap position in two places
`db.minimapAngle` and `db.minimapIcon.minimapPos` could disagree. **Fixed** — one key, with a migration.

### ARCH-001 — Dead code
`ns.TryPlayerMana`, `Locales.lua` / `ns.RegisterLocale`, and `ns.DB_DEFAULTS` are unused. **Removed.**

### TOOL-001 — luacheck
`.luacheckrc` missed `GameTooltip`, `Minimap`, and `GetCursorPosition`, and listed unused `GetLocale` and `UnitPower`. **Fixed.**

### TOC-001 — Game type
Updated to `forever` plus `## ExcludeLoadGameType: standard, classic`. Revert to `camelot` on a pre-70291 build.

## Verification

- `luacheck .` — clean.
- `luajit tests/run.lua` — 19 passed.
- LuaLS with Ketho's annotations — clean.

## In-game checklist

- Greater Heal shows a sane heal and heal-per-mana number.
- Check the same on a high rank (thousands) to confirm the client does not group digits.
- Renew and Power Word: Shield show numbers.
- Holy Nova shows the heal, not the damage.
- `/hpm` toggles the list; `/hpm settings`, the minimap button, and the compartment open settings.
- The addon loads (`/dump C_AddOns.IsAddOnLoaded("HealPerMana")`).
