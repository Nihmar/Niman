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

Once the first sync is done, Niman syncs by itself:

- **a few seconds after you stop editing**: only the files you changed
  are sent, one small request each (while you keep typing, at the
  latest after a minute);
- **when you leave the app**, if something is still waiting;
- **when the library opens and when you come back to the app**, and
  **every minute while it is open**: a full comparison with the server,
  which brings in what changed on other devices;
- **as soon as the network comes back** after an outage.

You can also sync by hand at any time: the **sync icon** in the Files bar
(phone) or at the bottom of the file tree (desktop), or **Sync now** in
Settings → Sync → WebDAV. A manual sync shows a progress bar under the
tree; an automatic one only turns the icon. You can keep writing either
way. Open notes are saved before a manual sync, and a note that sync
updated is reloaded.

#### When to sync

In Settings → Sync → WebDAV:

- **Automatically**: off, Niman syncs only when you ask.
- **Check the server every** 1, 5, 15 or 30 minutes, or **Never** (then
  only after edits and when the app opens). Each check lists every
  folder on the server: on a large library over a slow VPN, 5 minutes is
  kinder to the battery.
- **Wi-Fi only** (phones): on mobile data nothing syncs by itself; the
  changes wait, and go out when you are back on Wi-Fi. **Sync now** still
  works on mobile data.

#### Offline

Changes made without a connection wait in a queue that survives closing
the app. Niman tries again after 5 seconds, then 10, 20… up to every 10
minutes, and right away when the network comes back. The panel shows how
many changes are waiting and when the next try is; **Try again** goes
now.

Some problems need you, and automatic syncing pauses until you act: a
rejected password (update it), a missing folder on the server (fix the
address), or a sync that would remove many files (tap **Sync now** to
see what and decide). Syncing by hand lifts the pause.

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
- The library's own settings (`.niman/settings.json`, `.niman/counters.json`)
  are never deleted by a sync: if one goes missing on one side, it is put
  back from the other.
- If a sync would remove more than 10 files and more than half of the
  library, Niman stops and asks first. That is what a wrong address, an
  unmounted NAS disk or a folder emptied by mistake looks like.

### Conflicts

A note changed both here and on the server since the last sync is merged
when the edits are in different places: your new line at the end and the
title someone fixed on another device both survive, and you are not
asked anything. The note's [history](organization.md#history) keeps the
text the merge replaced.

Only edits to the **same lines** need you. Those files stay untouched on
both sides, the sync icon gets a dot, and **Resolve** opens the merge:

- everything that merged by itself is already there, marked with where it
  came from;
- each overlap shows both versions with a choice — **Mine**, **Theirs**
  or **Both**;
- **Save the merge** writes the result here and on the server;
- or keep one whole copy: **Keep this device's** uploads yours, **Keep
  the server's** replaces yours (which stays in the history).

Files with no version in common — created on both devices, or an
attachment — cannot be merged: there the two whole copies are shown as a
diff (lines marked − are the server's, + are this device's) and you keep
one.

Library settings (`.niman/settings.json`) never conflict: the newer copy
wins.

### When something goes wrong

The sync icon and its panel say what stopped a sync, and nothing is
touched when it stops:

| Message | What to do |
|---|---|
| Server not reachable | Check the network or the VPN, then **Try again**. Your changes wait and go out by themselves. |
| Password rejected by the server | **Update password** in the WebDAV settings. |
| The folder on the server is gone | Recreate it or fix the address. |
| Waiting for your confirmation | An automatic sync would have removed many files: **Sync now** shows what, and asks. |
| Waiting for Wi-Fi | **Wi-Fi only** is on and the phone is on mobile data. |
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
trash, history — except how the library looks on each device (tree
width, text size, editor), which stays with the device.

- Close the library on both sides before copying, to avoid half-written
  files (note writes themselves are atomic: temp file + rename).
- The search index is not in the folder; it is rebuilt from disk when
  needed.
- Unknown `settings.json` keys are kept, so a newer app version's
  settings survive a round trip through an older one.
- Don't combine the two: a folder synced by another tool *and* by Niman's
  WebDAV sync sees every change twice.
