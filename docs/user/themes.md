# Themes

Niman's colors have their own page: **Settings → Themes**. Brightness is
the first row — day, night, or whatever the device says — and under it sit
the themes, each with its colors in front of you, resolved at the
brightness on screen so a row reads the way choosing it would.

The one in use carries a filled mark on the left; tapping another wears it
at once, everywhere, and the choice is remembered on this device.

## The themes the app ships

| Theme | What it is |
|-------|------------|
| System | The device's own colors: the wallpaper palette (Material You on Android 12+, the accent color on Windows and GTK), falling back to Niman's own where the OS offers neither |
| Niman | The app's own colors, taken from the logo (the default) |
| Catppuccin | Latte by day, Mocha by night |
| Solarized | Schoonover's light and dark |
| Gruvbox | The medium light and dark variants |

The Markdown colors — code, links, quotes, tags — travel with the theme:
the editor and the preview always agree with the interface around them.

## Themes of your own

*New theme*, at the end of the list, asks for a name and where the colors
start from: a theme already in the list, shipped or your own, or *Random
colors* — a whole theme invented around one random hue, complete at day
and at night. Nothing has to be filled in from a blank page.

Each theme in the list carries a ⋮ menu:

- **Edit** (your own themes) opens the theme color by color: the interface
  roles first — background, text, accent, error — then the Markdown ones,
  each with the color it holds and the name the exported file uses. A
  color is opened in a picker with a saturation-and-value square, a hue
  bar and a `#RRGGBB` field, and **the whole app wears the colors as they
  move**, so a color is chosen by seeing it in place. The Light/Dark
  switch at the top picks which side of the theme is being edited, and
  previews that side, since editing the night colors in daylight would be
  editing blind. *Save* keeps the colors; leaving puts back what was
  there, after asking.
- **Duplicate** makes a theme of your own out of the one the menu is on,
  named after it (`Gruvbox 2`) and worn at once. The shipped themes offer
  only this: they can be copied, never renamed away.
- **Rename** and **Delete** act on your own themes. Deleting one asks
  first, naming it; deleting the theme in use leaves the app Niman's own
  colors.

Two themes cannot answer to the same name; a name already in the list —
shipped names included — is refused while it is typed.

## Moving a theme between installations

- **Export**, in a theme's ⋮ menu, writes that one theme into a single
  `.json` file wherever you say, through the system's own save dialog: the
  name, the format version, and the colors at day and at night. JSON and
  not an `.ini`, because a theme is two structured maps of twenty colors.
- **Import**, the row after *New theme*, reads such a file back. This is
  how a theme gets to another device: it is stored with the installation,
  not with the library, so it never travels in a synced folder. A file
  that is not a Niman theme, comes from a newer Niman, or is missing a
  color is refused with the reason — nothing half-imported lands. A file
  whose theme name is already taken is refused too, and offered to be
  imported under a name typed on the spot.

## Where they live

Custom themes live in the app's own database on the device, next to the
other app settings — not in the library. A copied library folder does not
carry them, a synced library does not spread them, and each installation
wears what it was given.
