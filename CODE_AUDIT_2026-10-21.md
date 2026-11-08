# Heal Per Mana Table audit

Target: World of Warcraft Forever, `## Interface: 16001` (client 1.60.1.70862), Lua 5.1.
Compared 2026-10-21 against ResourceEfficiencyTooltips 0.2.1 (2026-10-18) for
the shared inputs (`C_Spell.GetSpellPowerCost`, tooltip heal text) and
WhatsTraining 11.0.0-beta23 (2026-10-21) for spellbook scanning patterns.
Re-checked against client 1.60.1.70862 on 2026-11-08.

This note is for development. It is not shipped in the addon zip.

## What changed in 1.2.6

- Re-checked the spellbook scan and the guarded mana-cost read against
  client 1.60.1.70862. `C_SpellBook.GetSpellBookItemType`,
  `C_SpellBook.GetSpellBookItemInfo`, and `C_Spell.GetSpellPowerCost` keep
  their shapes. No code change.

## What changed in 1.2.5

- `ReadMana` reads `C_Spell.GetSpellPowerCost` as one guarded call, the
  same as Spell Resources, so a cost entry that is a combat secret is
  skipped instead of stopping the scan. Entry fields stay behind
  `ns.CanIndex` and `ns.ReadableNumber`.
- The Minimap button row stays active while the addon is off, and checkbox
  defaults now come from `ns.defaults`.

## Still holds

- The addon never annotates the game tooltip and never reads `UnitHealth`;
  both stay deliberate (the second is a secret value on this client).
- Spellbook scan: `C_SpellBook.GetSpellBookItemType` and
  `C_SpellBook.GetSpellBookItemInfo` both exist in the documented
  C_SpellBook API for this client family, with the return shapes used here
  and in the other Joipov addons respectively. No change was needed.
- The bare `/hpm` toggles the list. That is a recorded exception to the
  house "no argument opens settings" rule; the login line says so. See
  STYLE.md.

## Checked in the client (manual pass, 1.2.5)

- [ ] `/hpm` in and out of combat — every known heal rank lists with its
      mana cost; no scan errors in BugSack.
- [ ] Toggling **Show unlearned** re-scans without stale rows.
