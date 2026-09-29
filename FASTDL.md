# IW5 FastDL Operations

This document describes the FastDL configuration used by the dedicated IW5
server. It intentionally omits subscription identifiers, tenant identifiers,
account names, credentials, server keys, and the live public IP address.

## Purpose

Plutonium IW5 does not transfer custom maps directly from the game process.
When a connecting player does not already have a custom map, the client uses
`sv_wwwBaseURL` to download the required files from a separate HTTP server.

The existing Windows VM serves both roles:

```text
IW5 dedicated server  -> UDP game traffic
IIS Default Web Site  -> TCP/80 FastDL traffic
```

No additional persistent Azure service is required.

## Persistent Azure Configuration

The existing network security group has an inbound rule with the following
settings:

| Setting | Value |
| --- | --- |
| Name | `fastdl-http` |
| Direction | Inbound |
| Protocol | TCP |
| Destination port | `80` |
| Source | Internet |
| Action | Allow |

The rule exposes only HTTP. Existing RDP and game-server rules are independent.

## Persistent VM Configuration

IIS is installed with the `Web-Server` Windows feature. The Default Web Site
uses this physical root:

```text
C:\FastDL
```

The Windows Firewall contains an inbound TCP/80 rule named:

```text
IW5 FastDL HTTP
```

`C:\FastDL\web.config` registers static-file MIME mappings for the file types
used by Plutonium content, including `.ff`, `.arena`, `.iwi`, `.iwd`, `.files`,
`.csv`, `.wav`, `.gsc`, and `.csc`.

Directory browsing is not enabled. Players request known asset paths directly.

## Map Layout

Every custom map must exist in two matching locations on the VM:

```text
C:\gameserver\IW5\usermaps\<map-name>\...
C:\FastDL\iw5\usermaps\<map-name>\...
```

The game server loads the first copy. IIS sends the second copy to clients.
For example:

```text
C:\gameserver\IW5\usermaps\mp_example\mp_example.ff
C:\FastDL\iw5\usermaps\mp_example\mp_example.ff
```

The two trees should have identical relative paths, file counts, and byte
counts. The initial deployment contained 49 map directories, 196 files, and
3,735,302,115 bytes in each tree.

## Server Configuration

`C:\gameserver\IW5\admin\server.cfg` contains:

```cfg
seta sv_wwwBaseURL "http://<public-ip-or-domain>/iw5"
```

The one-time pre-FastDL backup is stored at:

```text
C:\gameserver\IW5\admin\server.cfg.pre-fastdl.backup
```

Restart the dedicated server after changing `sv_wwwBaseURL` so the setting is
loaded.

## Health and File Checks

The lightweight health endpoint is:

```text
http://<public-ip-or-domain>/iw5/health.txt
```

It should return HTTP 200 and the following body:

```text
IW5 FastDL ready
```

A real map asset should also return HTTP 200:

```text
http://<public-ip-or-domain>/iw5/usermaps/<map-name>/<asset-name>.ff
```

`.ff`, `.iwd`, and `.arena` files are served as
`application/octet-stream`.

## Updating Maps

Custom-map binaries are deliberately not stored in this Git repository. When
adding or updating a map:

1. Stop or move away from the affected map before replacing its files.
2. Upload the complete map folder to
   `C:\gameserver\IW5\usermaps\<map-name>`.
3. Mirror the server map tree to IIS:

   ```powershell
   robocopy "C:\gameserver\IW5\usermaps" "C:\FastDL\iw5\usermaps" /MIR /R:2 /W:2
   ```

4. Confirm that Robocopy returns an exit code from 0 through 7. Codes 8 and
   above indicate failure.
5. Verify one of the map's public `.ff` or `.iwd` URLs.
6. Add the map to the voting rotation only after both server loading and client
   download tests succeed.

Using `/MIR` means a deletion from the server tree is also deleted from the
FastDL tree. Review the source path carefully before running it.

## Initial Transfer Method

The initial 3.7 GB collection was transferred through a temporary private
Azure Blob Storage account:

1. The local `usermaps` tree was uploaded to a private container.
2. The VM downloaded it using a short-lived, read-only SAS URL and AzCopy.
3. The downloaded tree was validated and mirrored to IIS.
4. Real assets were tested over public HTTP.
5. The temporary storage account was deleted.

The staging account and SAS token were not retained. This transfer method can
be repeated for large future batches, but it is not part of the permanent
FastDL architecture.

## Security Notes

- FastDL content is public by design; do not place secrets anywhere beneath
  `C:\FastDL`.
- Keep server keys, RCON passwords, Azure identifiers, and credentials out of
  this repository and the web root.
- HTTP is sufficient for Plutonium's IP-based FastDL flow. A domain and HTTPS
  can be added later, but they are not required for the current configuration.
- The FastDL service does not require `fs_game` for standalone custom maps.

