# Random Bot Name Generator

This project uses a PowerShell script to generate random bot names for Bot Warfare in IW5 (MW3 Plutonium).

## How to Use

1. Run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\generate_iw5_bot_names.ps1"
```

By default, the generated names are written into `z_svr_bots.iwd` for both
the local Plutonium client and `C:\gameserver\IW5`. To update only one target,
use `-ClientOnly` or `-ServerOnly`. A different dedicated path can be supplied
with `-ServerRoot`:

```powershell
.\generate_iw5_bot_names.ps1 -ServerOnly -ServerRoot "D:\servers\IW5"
```

2. The script will:
   - Generate 17 unique bot names.
   - Save a local `bots.txt` beside the PowerShell script so the generated names can be reviewed.
   - Update `z_svr_bots.iwd` by adding/replacing `bots.txt` at the **root** of the archive.

3. Launch Plutonium MW3 and start a Private Match.

---

## Expected IWD Layout

Open `z_svr_bots.iwd` with WinRAR.

The archive should look like:

```text
z_svr_bots.iwd
├── bots.txt
├── maps/
└── scripts/
```

`bots.txt` should **not** be inside `maps` or `scripts`.

---

## Editing the IWD

- Open the archive directly with **WinRAR**.
- Drag or update files directly into the archive.
- Do **not** extract and recompress the archive.
- Verify that `bots.txt` exists at the archive root after running the PowerShell script.

---

## Name Generation

Each generated lobby contains:

- **6 constructed competitive aliases**
- **2 stylized competitive aliases**
- **5 general gaming names**
- **1 gamer/name hybrid**
- **2 early-2010s wannabe-MLG names**
- **1 Xbox-generated-style gamertag**

The competitive aliases appear first and the remaining styles are shuffled.
Every launch generates a fresh set of 17 unique names.

---

## Local bots.txt

The generator also creates:

```text
bots.txt
```

in the same directory as `generate_iw5_bot_names.ps1`.

This is only for reference so the generated names can be viewed without opening the archive.

---

## Bot Warfare

Repository:

https://github.com/ineedbots/iw5_bot_warfare

Documentation / Releases:

https://github.com/ineedbots/iw5_bot_warfare/releases

---

## Notes

- Bot names are generated **before** launching the game.
- The custom GSC naming approach was removed because IW5 does not allow changing `self.name` after the bot has connected.
- `bots.txt` is the supported mechanism for assigning bot names.
