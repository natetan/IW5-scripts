# IW5 Custom Scripts Agent Guide

## Scope

These instructions apply to all work in this repository. Treat the repository
as the editable source overlay. Plutonium storage, the dedicated server, and
FastDL directories are deployment targets, not alternate source trees.

Before changing behavior, read the relevant sections of `README.md`. For map
or hosting work, also consult `IW5_MAP_REFERENCE.md` or `FASTDL.md`.

## Change Discipline

- Preserve unrelated user changes and inspect the working tree before editing.
- Prefer a narrow overlay or `replacefunc` hook over copying additional stock
  scripts into the repository.
- Keep tunable balance values named or documented near the behavior they
  control.
- Guard GSC entity, array, team, HUD, and callback state before dereferencing
  it. Team changes, deaths, disconnects, and event ordering can invalidate
  otherwise-correct state.
- Verify stock function signatures and event order from an authoritative IW5
  script source before changing engine-facing calls.
- Do not commit server keys, RCON passwords, player GUIDs, public IP addresses,
  Azure identifiers, credentials, or generated deployment artifacts.

## Deployment Ownership

- `install_game_scripts.ps1` owns loose gameplay GSC, `players`, `admin`, and
  `maps` overlays. Run it after ordinary gameplay, gametype, configuration, or
  killstreak changes.
- `install_bot_scripts.ps1` owns Bot Warfare scripts and waypoint files inside
  `z_svr_bots.iwd`. Run it after changes under `gsc/bots` or `waypoints`.
- Custom-map assets under `usermaps` and their FastDL mirror use the separate
  process documented in `FASTDL.md`.
- On the VM, run installers without `-ClientOnly` or `-ServerOnly` when both
  `C:\gameserver\IW5` and the VM user's Plutonium storage must stay synchronized.
- Restart the map or server after deployment; copying a GSC file does not
  replace scripts already loaded by the current match.

## Verification

- Run `git diff --check` and inspect the scoped diff.
- When installing loose scripts locally, compare SHA-256 hashes between the
  repository source and `%LOCALAPPDATA%\Plutonium\storage\iw5` destination.
- Codex may receive a sandbox-redirected `%LOCALAPPDATA%`. If so, use the
  explicit real user storage path rather than treating an installer failure as
  a project error.
- State clearly what was verified statically, what was deployed, and what still
  requires an in-game test.

## Modification Documentation

When changing a documented system, update its reference in the same change:

- Weapon damage, ammunition, attachments, proficiencies, or loadouts:
  `modifications/WEAPONS.md`
- Perks or Specialist bonuses: `modifications/PERKS.md`
- Killstreak balance, replacements, activation, or feedback:
  `modifications/KILLSTREAKS.md`
- Global player mechanics or gameplay stability:
  `modifications/GAMEPLAY.md`

If a change crosses categories, update every affected reference. Keep exact
balance values in the repository documentation rather than duplicating them in
the external IW5 skill.

## Git Handoff

Do not commit unless the user asks. After every material repository change,
provide a scoped command block using `git add -- <specific paths>` followed by
a Conventional Commit-style message such as `[fix]`, `[feat]`, `[balance]`,
`[rework]`, `[docs]`, or `[perf]`. Never recommend `git add .`.

