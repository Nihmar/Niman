# Sync

Two ways to have the same library on more than one device: copy the
folder with a tool of your own, or let Niman sync it with a WebDAV
server.

## WebDAV sync

Niman syncs a library with a folder on any WebDAV server: Nextcloud,
ownCloud, a NAS (OpenMediaVault, Synology, QNAP), Apache or nginx with
WebDAV. Each library has its own destination, set on each device — a
library at home can go to the NAS and one at work to the office server.

### Set it up

1. **Settings → Sync → WebDAV.**
2. **Folder address**: the address of the folder on the server, as the
   server shows it, for example `https://cloud.example.com/remote.php/dav/files/you/Notes/`
   or `http://10.8.0.1:8080/webdav/Niman/`. The folder must already
   exist. `http://` works too — fine over a VPN or on your home network,
   where nothing travels over the open internet.
3. **User** and **Password**, or leave both empty if the server asks for
   none. The password is kept in the device's keychain (Android
   Keystore, Windows Credential Manager, the Linux keyring), never in the
   library's files.
4. **Test connection.** Niman tries reading, writing, renaming and
   deleting in a temporary folder on the server, removes it, and tells
   you what the server can do. A server that lacks some features (no
   ETags, no protected writes — common on small NAS WebDAV plugins) runs
   in **compatible mode**: sync works the same, with a few more requests.
5. **Save.** The first sync starts with a summary of what it will upload
   and download. **The first sync deletes nothing**, here or on the
   server: files on both sides are compared by content, identical ones
   are left alone.

### Syncing

For now sync runs when you ask for it (automatic syncing is coming):

- the **sync icon** in the Files bar (phone) or at the bottom of the file
  tree (desktop) — a tap syncs;
- **Sync now** in Settings → Sync → WebDAV.

While it runs, a bar under the tree shows the progress; you can keep
writing. Open notes are saved before it starts, and a note that sync
updated is reloaded.

What travels: every note and attachment, plus the library's
`.niman/settings.json` and `.niman/counters.json`. What stays on each
device: `.trash/`, `.history/`, any other dot folder (a `.git/`, for
example), and the files the operating system drops into folders
(`Thumbs.db`, `desktop.ini`).

### Deletions and the trash

- A file you delete here (into the trash, or for good) is deleted on the
  server at the next sync.
- A file that disappeared from the server — deleted on another device —
  is **moved to this device's trash**, never deleted outright. After such
  a sync a message offers **Show**, which opens the trash.
- If a sync would remove more than 10 files and more than half of the
  library, Niman stops and asks first. That is what a wrong address, an
  unmounted NAS disk or a folder emptied by mistake looks like.

### Conflicts

A file changed both here and on the server since the last sync is a
**conflict**: neither copy is touched. The sync icon gets a dot; tap it
to see the list, then **Resolve** a file:

- the two versions appear as a diff — lines marked − are the server's,
  lines marked + are this device's;
- **Keep this device's** uploads your copy over the server's;
- **Keep the server's** replaces your copy, which stays in the note's
  [history](organization.md#history), so nothing is lost.

Library settings (`.niman/settings.json`) never conflict: the newer copy
wins.

### When something goes wrong

The sync icon and its panel say what stopped a sync, and nothing is
touched when it stops:

| Message | What to do |
|---|---|
| Server not reachable | Check the network or the VPN, then **Try again**. |
| Password rejected by the server | **Update password** in the WebDAV settings. |
| The folder on the server is gone | Recreate it or fix the address. |
| Not synced · N | Those files are tried again at the next sync (a full disk on the server, for example). |

### Change or disconnect

In Settings → Sync → WebDAV:

- **Address, user and password** changes the destination. A different
  address or user makes the next sync a first sync again (which deletes
  nothing). Leave the password empty to keep the saved one.
- **Test the server again** refreshes what Niman knows about the server
  (it also does so by itself every 30 days).
- **Disconnect this library** stops syncing on this device and forgets
  the password. No file is deleted, here or on the server.

Forgetting a library from the home screen disconnects it too.

## Copying the folder yourself

A library is a plain folder with its settings in `.niman/`, so any tool
that copies folders works too (Syncthing, a Nextcloud client, rsync, a
USB stick). Everything travels: notes, folders, templates, settings,
trash, history.

- Close the library on both sides before copying, to avoid half-written
  files (note writes themselves are atomic: temp file + rename).
- The search index is not in the folder; it is rebuilt from disk when
  needed.
- Unknown `settings.json` keys are kept, so a newer app version's
  settings survive a round trip through an older one.
- Don't combine the two: a folder synced by another tool *and* by Niman's
  WebDAV sync sees every change twice.
