# Changelog

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
