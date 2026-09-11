# Niman — App Icons

Brand: N monogram in negative on a solid tile.
Ink `#23262b` · indigo accent `#587cd3` · letter `#f2ede5`.

Scaling rule applied in exports:
- ≥ 40 px: full version, with indigo accent.
- 32–39 px: without accent (single-color).
- < 32 px: reduced artwork (strokes 13/100, radius 20/100), without accent.

## android/
`res/mipmap-*/ic_launcher.png` (48→192) legacy, rounded corners.
`res/mipmap-*/ic_launcher_foreground.png` (108→432) adaptive layer, transparent background,
to be paired with `res/values/ic_launcher_background.xml` (#23262B).
`play-store-512.png` full square, as required by the Play Console.

## ios/ and ipados/
Squares, without transparency and without rounded corners: the system applies the mask.
Rename according to your `Contents.json` (e.g., AppIcon-120 → Icon-60@2x).

## macos/
10% margin and rounded corners, as per Apple convention.
To build the `.icns`, rename `icon_NxN-2x.png` → `icon_NxN@2x.png`
(the @ character was replaced during export), put everything in `niman.iconset/`
and run `iconutil -c icns niman.iconset`.

## windows/
`icon-16…256.png` sources for the `.ico` (Inno Setup / executable).
`Square44x44Logo.png` and `Square150x150Logo.png` for the MSIX package.

## linux/
`hicolor/<size>/apps/niman.png` tree to copy into `/usr/share/icons/hicolor/`;
the `.desktop` file must have `Icon=niman`.

## svg/
The vector masters: round, square, monochrome, reduced, inverted, adaptive layer.