/// The theme a book is read in (#280): the library's look for its books
/// ([EpubLooks]) over the app's own.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/palettes.dart';

/// The family [font] is drawn in, and the ones tried after it: a platform
/// names its serif and its monospace its own way (Windows has no `serif`
/// alias), so the common faces follow.
({String? family, List<String>? fallback}) epubFontFamily(EpubFont font) =>
    switch (font) {
      EpubFont.literata => (family: 'Literata', fallback: null),
      EpubFont.serif => (
        family: 'serif',
        fallback: const ['Noto Serif', 'DejaVu Serif', 'Georgia'],
      ),
      // The app's own face: nothing to name.
      EpubFont.sans => (family: null, fallback: null),
      EpubFont.mono => (
        family: 'monospace',
        fallback: const ['Consolas', 'DejaVu Sans Mono', 'Roboto Mono'],
      ),
    };

/// What [font] reads as in the sheet.
String epubFontLabel(EpubFont font) => switch (font) {
  EpubFont.literata => 'Literata',
  EpubFont.serif => AppStrings.epubFontSerif,
  EpubFont.sans => AppStrings.epubFontSans,
  EpubFont.mono => AppStrings.epubFontMono,
};

/// The theme a book is read in at [context]: the books' theme, or the
/// app's, at the books' brightness, or the app's, in the books' face.
///
/// The app's own theme is kept as it is when the books ask for nothing
/// else, so a book on the app's colors is on exactly the note's.
ThemeData epubThemeOf(BuildContext context) {
  final app = Theme.of(context);
  final look = EpubLooks.look;
  final named = EpubLooks.theme;
  final brightness = switch (look.brightness) {
    null => app.brightness,
    AppBrightness.day => Brightness.light,
    AppBrightness.night => Brightness.dark,
    AppBrightness.system => MediaQuery.platformBrightnessOf(context),
  };
  final base = named == null && brightness == app.brightness
      ? app
      : buildAppTheme(named ?? AppThemes.effective, brightness);
  final face = epubFontFamily(look.font);
  if (face.family == null) return base;
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: face.family,
      fontFamilyFallback: face.fallback,
    ),
  );
}

/// The scaler a book's text is read at: the platform's, times the books'
/// size — the interface slider taken back off, as a note's is.
TextScaler epubTextScalerOf(BuildContext context) =>
    ComposedTextScaler(platformTextScalerOf(context), EpubLooks.look.textScale);
