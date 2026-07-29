# Random Bot Name Generator

This project uses a PowerShell script to generate random bot names for Bot Warfare in IW5 (MW3 Plutonium).

## How to Use

1. Run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\generate_iw5_bot_names.ps1"
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

- **Bots 1–3:** Competitive "try-hard" names (e.g. `Voidix`, `Solaris`, `Fatalyx`)
- **Bots 4–6:** Mostly Xbox Live sweaty names (e.g. `xXRapidSniperXx`)
- **Remaining bots:** Mostly Xbox-generated gamertags (e.g. `FlyingOtter27`, `MuscledCupid12`)

Every launch generates a fresh set of names.

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