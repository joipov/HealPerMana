<!-- Self-audit of HealPick 1.0.0, written after the first playable build. -->

# HealPick: Code Quality, Compatibility and Performance Audit

## 0. Scope, method and evidence

**Repository**: `c:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\HealPick` (v1.0.0).

**Files inspected (100% of production and tooling sources)**:

| File | Role |
| --- | --- |
| `HealPick.toc` | Load order, camelot gate, SavedVariables |
| `Data.lua` | Families, catalog fallbacks, presets |
| `Locales/enUS.lua` | UI strings |
| `Locales.lua` | Overlay hook |
| `Secrets.lua` | Secret-value guards, class/mana reads |
| `Database.lua` | Defaults, version, validation |
| `Parse.lua` | Heal-text extract + tooltip fetch |
| `Scanner.lua` | Spellbook walk, catalog probe, cache |
| `Recommender.lua` | Pure scoring and sequences |
| `UI.lua` | Main window |
| `HUD.lua` | Pocket strip |
| `Events.lua` | Event frame |
| `Options.lua` | Settings + slash |
| `tests/run.lua` | Isolated unit tests |
| `.luacheckrc`, `.luarc.json`, `.annotations/Wow.lua` | Tooling |
| `README.md`, `CHANGELOG.md` | Docs |

**Unreviewed**: none of the addon tree. **Gaps**: no in-game session on `WowB.exe` yet; no luacheck binary on this machine; unit tests were run under Fengari (Lua 5.3 JS), not Lua 5.1 / LuaJIT.

**Target client (confirmed from this install)**: `wow_classic_beta` 1.60.1.70009, game type `camelot` (WoW Forever). TOC is `## Interface: 16001` and `## AllowLoadGameType: camelot`.

**References used (not assumed)**:

- EllesmereUI Forever gate and `C_Spell` / `C_SpellBook` usage in this install
- EllesmereUI QoL `C_TooltipInfo.GetHyperlink` (no scanning GameTooltip)
- GatherSkillTooltip module layout, secret guards, DB versioning, luacheck, tests
- warcraftforever.games addon notes: secret values, protected `ChatFrame_OpenChat`, `PlaySound` + SOUNDKIT

---

## Part 1: Executive summary

HealPick is a new, single-purpose priest planner. It does not read `UnitHealth` or drive casts. Ranking is a pure function. UI updates are event-driven with a 0.15 s debounce on `SPELLS_CHANGED` / `PLAYER_EQUIPMENT_CHANGED`. There is no `OnUpdate`. Rows are pooled. Intentional globals are the SavedVariables table, the compartment callback, two slash keys, and the `SlashCmdList` entry.

**Major observations**:

1. Live heal amounts depend on tooltip/description wording that has not been captured on this client (`COMPAT-001`). Catalog numbers are Classic-era fallbacks and are labeled `est.`
2. Spellbook rank listing vs collapsed ranks is unproven (`COMPAT-002`). Both a book walk and a catalog `IsSpellInSpellBook` probe are in place.
3. `UI.lua` is long (~840 lines) but one concern. A later split is optional, not required for correctness.
4. Talent/trait changes may not invalidate the cache if they do not fire `SPELLS_CHANGED` (`COMPAT-003`).
5. Static checks: 26/26 unit tests passed. luacheck was not executed here (no local binary).

**Requires in-game verification**: tooltip parse on a real heal rank; whether every rank appears in the book; `GetSpellSubtext`; player mana secrecy in and out of combat; haste vs `castTime`; no AddOn action-failed increment after opening the window and copying a macro.

---

## Part 2: Findings register

Severity: Critical = breaks the addon or corrupts data; High = wrong behavior users will hit; Medium = realistic edge cases or missing verification; Low = maintainability.

### Correctness

- **CQ-001** | Correctness | **Low** (fixed in 1.0.0 before this report)
  - Location: `Scanner.lua` `MakeSpell`
  - Evidence: An earlier draft preferred `catalogEntry.rank` over the live `ReadRank` result whenever a catalog row existed.
  - Problem: A remapped Forever spell ID would show the Classic rank number.
  - Recommendation: Prefer the live rank, catalog only as fallback. Applied.
  - Risk: none.
  - Verification: `/healpick debug` rank column matches the spellbook.

- **CQ-002** | Correctness | **Medium**
  - Location: `Parse.lua` `ParseHealText`
  - Evidence: First `(%d+)%s+to%s+(%d+)` in the concatenated tooltip wins.
  - Problem: If a Forever tooltip includes another range (level band, rank range) before the heal range, min/max will be wrong and still tagged as live.
  - Recommendation: After the first in-game dump, tighten the pattern (e.g. require `heal`/`Heals` nearby) if a false range appears.
  - Risk: a tighter pattern might miss a valid locale.
  - Verification: `/healpick debug` on Lesser Heal, Heal, Flash Heal, Renew, PW:S; compare to the tooltip.

- **CQ-003** | Correctness | **Low**
  - Location: `Recommender.lua` `HotHealInWindow`
  - Evidence: Assumes 5 ticks and first tick at `duration/ticks`.
  - Problem: If Forever Renew tick count or timing differs, windowed heal is off.
  - Recommendation: Keep 5 as the vanilla default; adjust only after an in-game tick check.
  - Verification: Renew Rank 1, window 3s should count one tick if the 3 s interval holds.

### Compatibility

- **COMPAT-001** | Compatibility | **High** (verification, not a known defect)
  - Location: `Parse.lua` `FetchHealText`, `Scanner.lua` `HealFromLiveOrCatalog`
  - Evidence: Heal numbers come from `C_TooltipInfo.GetHyperlink(C_Spell.GetSpellLink(id))` then `C_Spell.GetSpellDescription`, then catalog.
  - Problem: Exact Forever wording is unknown. If both live sources fail, every row is `est.` Classic-era data.
  - Recommendation: First priest session: debug dump `source` per rank. If all `catalog`, inspect one tooltip and extend the parser.
  - Risk: none if fallback stays labeled.
  - Verification: `/healpick debug` prints `tooltip`, `description`, or `catalog`.

- **COMPAT-002** | Compatibility | **Medium**
  - Location: `Scanner.lua` `ScanSpellbook`, `ProbeCatalog`
  - Evidence: Modern spellbooks sometimes collapse ranks.
  - Problem: If the book only lists the highest rank, the catalog probe must succeed via `C_SpellBook.IsSpellInSpellBook`.
  - Recommendation: Already implemented. Confirm lower ranks appear as `known=true`.
  - Verification: Priest with Heal Rank 3 learned: Rank 1–3 listed, not only 3.

- **COMPAT-003** | Compatibility | **Medium**
  - Location: `Events.lua` registrations
  - Evidence: Cache invalidates on `SPELLS_CHANGED` and `PLAYER_EQUIPMENT_CHANGED` only.
  - Problem: Forever traits may change +heal on the tooltip without those events.
  - Recommendation: If an in-game talent swap leaves stale numbers, register the trait event that actually fires on camelot (do not register a guessed name).
  - Verification: Change a healing talent, reopen `/healpick` without `/reload`; numbers should move. If not, note the event from `/eventtrace`.

- **COMPAT-004** | Compatibility | **Low**
  - Location: `Scanner.lua` existence guards on `C_Spell.*`
  - Evidence: Forever-only TOC; these APIs are present in EllesmereUI on this build.
  - Problem: Extra branches are dead if the API set is stable.
  - Recommendation: Leave the guards at the API boundary (defensive). Do not add more client flavors.
  - Verification: none required.

### Security / taint

- **SEC-001** | Security | **Low** (accepted)
  - Location: `UI.lua` macro `EditBox`; no `ChatFrame_OpenChat`
  - Evidence: Macro text is highlighted for Ctrl+C. Forever treats `ChatFrame_OpenChat` as protected.
  - Problem: none found.
  - Recommendation: keep it this way.
  - Verification: copy a macro in combat; AddOn failure count must not increase.

- **SEC-002** | Security | **Low** (accepted)
  - Location: `Secrets.lua`, planner inputs
  - Evidence: Deficit and window are typed numbers. `UnitHealth` is never called. `UnitPower` is used only after `ReadableNumber`.
  - Problem: none found.
  - Recommendation: do not add auto-deficit from `UnitHealthMissing`.
  - Verification: combat `/healpick` with a friendly target; no secret-value errors.

### Architecture

- **ARCH-001** | Architecture | **Low**
  - Location: `UI.lua` (~840 lines)
  - Evidence: Planner, card, table pool, and refresh live in one file.
  - Problem: Harder to review than GatherSkillTooltip’s post-split modules; still one concern.
  - Recommendation: Split only if a second window or a second class lands.
  - Risk: a split without tests would be churn.
  - Verification: n/a

### Performance

- **PERF-001** | Performance | **Low** (hypothesis)
  - Location: `Parse.lua` `FetchHealText` during `ScanSpells`
  - Evidence: One tooltip/description fetch per rank on cache miss. Rank count is tens, not hundreds. Debounced 0.15 s.
  - Problem: No demonstrated bottleneck. TooltipInfo on every equipment change is the only recurring cost.
  - Recommendation: Do not cache across sessions. Do not poll.
  - Verification: `/healpick debug` after swapping a +heal piece; UI updates once, not every frame.

- **PERF-002** | Performance | **Low** (accepted)
  - Location: `UI.lua` `CreateMainFrame`
  - Evidence: Frame is created on first `/healpick` (or first HUD compute does not create it). Rows grow to the visible spell count and are reused.
  - Problem: none found.
  - Recommendation: keep lazy window creation.

### Tooling

- **TOOL-001** | Tooling | **Medium**
  - Location: development environment
  - Evidence: This machine has no `lua`, `luajit`, or `luacheck` on PATH. Tests were run with Fengari 5.3.
  - Problem: CI-equivalent Lua 5.1 was not executed locally. Fengari passed 26 tests; 5.1-only bugs would not show.
  - Recommendation: Run `lua5.1 tests/run.lua` and `luacheck .` when those binaries exist (same as GatherSkillTooltip CI).
  - Verification: both commands exit 0.

---

## Part 3: Prioritized remediation roadmap

### Phase 1 — In-game verification (no code unless a probe fails)

| Task | Benefit | Complexity | Deps | Risk | Acceptance |
| --- | --- | --- | --- | --- | --- |
| Debug-dump ranks on Joi | Confirms parse + book | Small | priest log-in | none | `/healpick debug` shows live sources |
| Combat secret check | No Lua errors | Small | combat | none | no secret arithmetic errors |
| Macro copy | No protected-action counter | Small | none | none | AddOn failure count unchanged |

### Phase 2 — Only if probes fail

| Task | Benefit | Complexity | Deps | Risk | Acceptance |
| --- | --- | --- | --- | --- | --- |
| Tighten `ParseHealText` | Correct live heals | Small | COMPAT-001 | locale miss | debug source stays `tooltip` |
| Trait event | Fresh +heal | Small | COMPAT-003 | wrong event name | talent swap updates table |
| Catalog ID remap | Known ranks if IDs changed | Medium | COMPAT-002 | duplicates | every learned rank listed |

### Phase 3 — Maintainability (optional)

| Task | Benefit | Complexity | Deps | Risk | Acceptance |
| --- | --- | --- | --- | --- | --- |
| Split `UI.lua` | Easier review | Medium | none | layout regressions | window identical |
| Local luacheck | Catch globals | Small | TOOL-001 | false positives | clean run |

**Quick wins**: the Phase 1 probes. Do not rewrite the recommender or add Ace.

---

## Part 4: Performance optimization plan

| Opportunity | Impact | Confidence | Status |
| --- | --- | --- | --- |
| Debounced rescan (already in) | Avoids SPELLS_CHANGED storms | High | shipped |
| Row pool (already in) | No per-refresh frame churn | High | shipped |
| Skip UI work while hidden | No table rebuild | High | shipped |
| Cache tooltip text across equipment events | Fewer TooltipInfo calls | Low | **do not** without a measured hitch |
| OnUpdate HUD | Would add per-frame work | n/a | rejected |

No invented timings. Nothing here is labeled slow from appearance alone.

---

## Part 5: Coding standards for this repository

1. **Lua 5.1 only.** Locals by default. Cache API tables as file locals where the file calls them often.
2. **Globals.** Only `HealPickDB`, `HealPick_OnAddonCompartmentClick`, `SLASH_HEALPICK1/2`, `SlashCmdList.HEALPICK`.
3. **Modules.** `local _, ns = ...`. One concern per file. Events.lua is the only load-time frame.
4. **Forever API.** `C_Spell`, `C_SpellBook`, `C_TooltipInfo`. No `GetSpellInfo`. No `UnitHealth` math.
5. **Secrets.** `SecretBlocked` / `ReadableNumber` / `ReadableString` at every unit/API boundary. Never compare or add secrets.
6. **Events.** Register only what is needed. Debounce bursts. No `OnUpdate`.
7. **UI.** Pool rows. Do not create scanning tooltips. `PlaySound` + SOUNDKIT only. No secure buttons in v1.
8. **Errors.** Validate SavedVariables on load. Do not `pcall` to hide bugs.
9. **Tests.** Pure logic in `Recommender.lua`, `Parse.lua`, `Database.lua` must stay loadable without WoW.
10. **No extra libraries.**

---

## Part 6: Implementation and verification checklist

### Static

- [x] Every production Lua file read for this audit
- [x] Unit tests: 26 passed (Fengari)
- [ ] `luacheck .` on Lua 5.1 (blocked: no binary)
- [ ] `lua5.1 tests/run.lua` (blocked: no binary)

### In-game (priest)

- [ ] `/reload`, `/healpick` — window opens, drag persists
- [ ] Table fills with learned ranks
- [ ] Non-priest character shows the priest-only note
- [ ] `500` / `10` / Efficient — covering rank, not an oversized Greater Heal if a cheaper rank fits
- [ ] Fast prefers a shorter cast when it still covers
- [ ] `1200` / `10` — sequence if one cast cannot cover
- [ ] HoT chip: Renew listed; planner ticks clipped
- [ ] Equip +heal (if any) — numbers refresh without `/reload`
- [ ] Combat: no Lua errors, no AddOn action-failed increment
- [ ] `/healpick debug` — record `source` per rank for COMPAT-001

### Do not do

- Auto-cast or click-to-heal
- `UnitHealth` deficit fill
- `ChatFrame_OpenChat` for macros
- Ace / EllesmereUI hard dependency

## 1.1.0 alignment

Docs, TOC, and packaging now match the other Joipov addons. The rank list is unchanged.

Checked with luacheck (Lua 5.1, explicit globals). SavedVariables, slash commands, and the compartment callback are the globals this addon writes.

`assets/` is release media for CurseForge and Wago. It is not loaded by the TOC, not shipped in the zip, and not part of this audit.

## Practices (2026-10-10)

Checked against the Joipov house style and against Warcraft Wiki secret values plus the Ketho WoW API library in `.luarc.json`.

The event frame was already a handler table. `ADDON_LOADED` already unregisters itself. Rescans already use one coalesced `C_Timer.After`. There is no `OnUpdate`.

This pass exports `ns.defaults` as an alias of `ns.DB_DEFAULTS`. After `CopyDefaults` fills a missing boolean, `showMinimapButton` is kept only when it is `true`, matching the other addons.

Left alone: tooltip parsing, rank selection, and the open compatibility notes above.
