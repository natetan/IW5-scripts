# IW5 Map Reference

This document maps IW5's internal map names to their player-facing display
names. It also records which maps have been tested successfully and which are
included in this server's post-game map vote.

The standard MW3 and DLC tables came from the imported IW5 Bot Warfare
waypoint collection. The expanded Plutonium table also cross-references a
larger local waypoint pack. A waypoint file only provides bot navigation data;
it does not include the map itself. The server and every connecting player
must also have compatible map assets for the map to load.

## Status definitions

- **Playable — Yes:** The map has been launched and confirmed working.
- **Playable — Untested:** Compatible assets are installed, but the map has
  not yet been manually verified.
- **Playable — No:** Required compatible map assets are not installed locally.
- **Map vote — Yes:** The map is included in `mapvote_maps` and can appear as
  one of the twelve randomly selected post-game choices.
- **Map vote — No:** The map is intentionally unavailable in the vote pool.
- **Waypoint source — Available:** A matching waypoint script is tracked under
  `waypoints` and is packaged into `z_svr_bots.iwd` by the bot installer.
- **Waypoint source — Missing:** No matching waypoint script was found in
  either local waypoint collection.

## Base MW3 maps

| Internal name | Display name | Playable | Map vote | Notes |
|---|---|:---:|:---:|---|
| `mp_alpha` | Lockdown | Yes | Yes | |
| `mp_bootleg` | Bootleg | Yes | Yes | |
| `mp_bravo` | Mission | Yes | Yes | |
| `mp_carbon` | Carbon | Yes | Yes | |
| `mp_dome` | Dome | Yes | Yes | |
| `mp_exchange` | Downturn | Yes | No | Excluded by preference. |
| `mp_hardhat` | Hardhat | Yes | Yes | |
| `mp_interchange` | Interchange | Yes | No | Excluded by preference. |
| `mp_lambeth` | Fallen | Yes | Yes | |
| `mp_mogadishu` | Bakaara | Yes | Yes | |
| `mp_paris` | Resistance | Yes | Yes | |
| `mp_plaza2` | Arkaden | Yes | Yes | |
| `mp_radar` | Outpost | Yes | Yes | |
| `mp_seatown` | Seatown | Yes | Yes | |
| `mp_underground` | Underground | Yes | Yes | |
| `mp_village` | Village | Yes | Yes | |

## Free DLC maps

| Internal name | Display name | Playable | Map vote | Notes |
|---|---|:---:|:---:|---|
| `mp_terminal_cls` | Terminal | Yes | Yes | |
| `mp_aground_ss` | Aground | Yes | Yes | |
| `mp_courtyard_ss` | Erosion | Yes | Yes | |

## DLC Collection 1

| Internal name | Display name | Playable | Map vote | Notes |
|---|---|:---:|:---:|---|
| `mp_italy` | Piazza | No | No | Compatible map assets are missing. |
| `mp_overwatch` | Overwatch | Yes | Yes | |
| `mp_morningwood` | Black Box | No | No | Compatible map assets are missing. |
| `mp_park` | Liberation | No | No | Compatible map assets are missing. |

## DLC Collection 2

| Internal name | Display name | Playable | Map vote | Notes |
|---|---|:---:|:---:|---|
| `mp_meteora` | Sanctuary | No | No | Compatible map assets are missing. |
| `mp_cement` | Foundation | Yes | No | Excluded by preference. |
| `mp_qadeem` | Oasis | No | No | Compatible map assets are missing. |
| `mp_restrepo_ss` | Lookout | No | No | Compatible map assets are missing. |
| `mp_hillside_ss` | Getaway | No | No | Compatible map assets are missing. |

## DLC Collection 3

| Internal name | Display name | Playable | Map vote | Notes |
|---|---|:---:|:---:|---|
| `mp_crosswalk_ss` | Intersection | No | No | Compatible map assets are missing. |
| `mp_burn_ss` | U-Turn | No | No | Compatible map assets are missing. |
| `mp_six_ss` | Vortex | No | No | Compatible map assets are missing. |

## DLC Collection 4

| Internal name | Display name | Playable | Map vote | Notes |
|---|---|:---:|:---:|---|
| `mp_boardwalk` | Boardwalk | Yes | Yes | |
| `mp_moab` | Gulch | No | No | Compatible map assets are missing. |
| `mp_roughneck` | Off Shore | Yes | Yes | |
| `mp_shipbreaker` | Decommission | No | No | Compatible map assets are missing. |
| `mp_nola` | Parish | Yes | Yes | |

## Plutonium and imported maps

This table is alphabetized by display name. All entries have compatible local
map assets. The `Playable` column remains `Untested` until a map successfully
starts in a manual test.

`Origin` identifies the game in which the original map debuted; custom variants
retain their source game's lineage where applicable.

| Display name | Internal name | Origin | Playable | Map vote | Waypoint source | Notes |
|---|---|---|:---:|:---:|:---:|---|
| Ambush | `mp_convoy` | COD4 | Yes | Yes | Available | |
| Broadcast | `mp_broadcast` | COD4 | Yes | Yes | Available | |
| Carnival | `mp_abandon` | MW2 | Yes | No | Missing | Playable, but excluded because bots lack waypoints. |
| Countdown | `mp_countdown` | COD4 | Yes | Yes | Available | |
| Crash | `mp_crash` | COD4 | Yes | Yes | Available | |
| Crossfire | `mp_cross_fire` | COD4 | Yes | Yes | Available | Use this variant; `mp_crossfire` has no matching waypoint source. |
| Derail | `mp_derail` | MW2 | Yes | Yes | Available | |
| District | `mp_citystreets` | COD4 | Yes | Yes | Available | |
| Estate | `mp_estate` | MW2 | Yes | Yes | Available | |
| Favela | `mp_favela` | MW2 | Yes | Yes | Available | |
| Highrise | `mp_highrise` | MW2 | Yes | Yes | Available | |
| Invasion | `mp_invasion` | MW2 | Yes | No | Missing | Playable, but excluded because bots lack waypoints. |
| Karachi | `mp_checkpoint` | MW2 | Yes | Yes | Available | |
| Nuketown | `mp_nuked` | Black Ops | Yes | Yes | Available | |
| Overgrown | `mp_overgrown` | COD4 | Yes | Yes | Available | |
| Pipeline | `mp_pipeline` | COD4 | Yes | Yes | Available | |
| Raid | `mp_raid` | BO2 | Yes | Yes | Available | |
| Rust | `mp_rust` | MW2 | Yes | Yes | Available | |
| Rust: Long | `mp_rust_long` | Custom (MW2-derived) | Yes | Yes | Available | |
| Salvage | `mp_compact` | MW2 | Yes | Yes | Available | |
| Scrapyard | `mp_boneyard` | MW2 | Yes | Yes | Available | |
| Shipment | `mp_shipment` | COD4 | Yes | Yes | Available | |
| Showdown | `mp_showdown_sh` | COD4 | Yes | Yes | Available | |
| Skidrow | `mp_nightshift` | MW2 | Yes | Yes | Available | |
| Storm | `mp_storm` | MW2 | Yes | Yes | Available | |
| Sub Base | `mp_subbase` | MW2 | Yes | Yes | Available | |
| Trailer Park | `mp_trailerpark` | MW2 | Yes | Yes | Available | |
| Underpass | `mp_underpass` | MW2 | Yes | Yes | Available | |
| Vacant | `mp_vacant` | COD4 | Yes | Yes | Available | |
| Wasteland | `mp_brecourt` | MW2 | Yes | Yes | Available | |
