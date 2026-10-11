# Changelog

## 1.2.1

Heal text parsing is more accurate for Renew, Power Word: Shield, Holy Nova, and grouped numbers.

### Fixed

- **Renew** parses again: the heal text puts "damage" between the amount and "over", which the old pattern missed.
- **Power Word: Shield** parses again: it absorbs, and the old pattern only matched "absorb" or "absorbs" with no suffix.
- **Holy Nova** and Prayer of Healing use the group heal range, not the damage range that is named first.
- Numbers with thousands separators (such as "1,966 to 2,195") are parsed correctly.

### Changed

- The minimap position is stored in LibDBIcon's own table, so dragging the button with LibDBIcon keeps its place, and the built-in button uses the same value.
- The addon loads only on the `forever` game type.

### Removed

- The unused locale loader (`Locales.lua`) and `ns.TryPlayerMana`.

## 1.1.5

Penance ranks are in the heal list.

### Added

- Penance ranks 1–4. The heal column is the full channel, three bolts for one mana cost.

## 1.1.4

Settings use the same wording as the other Joipov addons.

### Changed

- **Enable Heal Per Mana Table** says it shows the heal rank window.
- **Minimap button** is sentence case.
- The other rows grey out while the addon is off.

## 1.1.3

The minimap button is on by default. The addon compartment opens settings.

### Changed

- **Minimap Button** sits under Enable and starts on. Click opens settings. `/hpm` still toggles the list.
- The button uses LibDBIcon when that library is loaded, and the same frame name when it is not, so the default minimap, the addon compartment, Ellesmere, and ElvUI can all show it.

## 1.1.2

Heal, mana, cast, and rank come from the client each time the list is drawn.

### Changed

- A value the client does not return shows N/A.
- Opening or sorting the list reads the client again.
- The addon list groups this under Joipov Tools. The list name has no Joipov prefix.

### Removed

- Stored Classic heal, mana, and cast numbers.

## 1.1.1

Heal Per Mana loads on its own. Chat lines no longer go through another addon.

### Changed

- Chat lines are printed by this addon. One login line tells you `/hpm`.

## 1.1.0

Renamed to Heal Per Mana. The window is the rank list only.

### Changed

- Command is `/hpm`.
- Columns are spell, rank, cast, mana, heal, and heal per mana.

### Removed

- Planner (deficit, time, goal, presets), Fit column, heal bars, filter chips, recommendation card, and pocket HUD.

## 1.0.0

First release for WoW Forever (`camelot`, Interface 16001).

### Added

- Priest heal ranks sorted by heal per mana.
