/// How the books look (#280): the sheet the book's Aa button opens and
/// Settings → Appearance opens too, on the same values.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/epub_theme.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/theme_row.dart';

/// What the books' [look] reads as on its Settings row: the face and the
/// size, what changes the reading most.
String epubLookSummary(EpubLook look) {
  final size = AppStrings.textScaleValue(look.textScale);
  return '${epubFontLabel(look.font)} · $size';
}

/// Opens the sheet that sets how [session]'s books look. Every pick is
/// kept at once, and an open book follows it behind the sheet.
Future<void> showEpubLookSheet(
  BuildContext context, {
  required LibrarySession session,
}) => showActionSheet<void>(
  context,
  sheetKey: const Key('epub-look-sheet'),
  title: AppStrings.epubLookTitle,
  items: (context) => [EpubLookPanel(session: session)],
);

/// The books' theme, brightness, font and text size.
final class EpubLookPanel extends StatefulWidget {
  /// The panel for [session]'s books.
  const new({required this.session, super.key});

  /// The session holding the settings.
  final LibrarySession session;

  @override
  State<EpubLookPanel> createState() => _EpubLookPanelState();
}

final class _EpubLookPanelState extends State<EpubLookPanel> {
  /// Steps of 5% between [minTextScale] and [maxTextScale], as the note
  /// text size has.
  static final int _textScaleSteps = ((maxTextScale - minTextScale) * 20)
      .round();

  EpubLook? _look;
  List<CustomTheme> _custom = const <CustomTheme>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final look = await widget.session.epubLook;
    final custom = await widget.session.customThemes();
    if (!mounted) return;
    setState(() {
      _look = look;
      _custom = custom;
    });
  }

  Future<void> _set(EpubLook look) async {
    setState(() => _look = look);
    await widget.session.setEpubLook(look);
  }

  /// Shows [look] on the open book while the slider moves; it is kept
  /// when the slider is let go.
  void _preview(EpubLook look) {
    setState(() => _look = look);
    EpubLooks.apply(look, theme: EpubLooks.theme);
  }

  /// Every theme a book can wear, by id: the shipped palettes, then the
  /// user's own.
  List<(String, String)> get _themes => [
    for (final palette in AppPalette.values)
      (BuiltinAppTheme(palette).id, builtinThemeLabel(palette)),
    for (final theme in _custom) (CustomAppTheme(theme).id, theme.name),
  ];

  @override
  Widget build(BuildContext context) {
    final look = _look;
    if (look == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    final themes = _themes;
    // A custom theme deleted since it was picked: the book wears the app's.
    final theme = themes.any((entry) => entry.$1 == look.theme)
        ? look.theme
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _choice<String?>(
          key: const Key('epub-look-theme'),
          title: AppStrings.themeTitle,
          value: theme,
          options: [
            (null, AppStrings.epubSameAsApp),
            for (final (id, label) in themes) (id, label),
          ],
          onChanged: (id) => unawaited(
            _set(
              id == null
                  ? look.copyWith(clearTheme: true)
                  : look.copyWith(theme: id),
            ),
          ),
        ),
        _choice<AppBrightness?>(
          key: const Key('epub-look-brightness'),
          title: AppStrings.themeBrightnessTitle,
          value: look.brightness,
          options: [
            (null, AppStrings.epubSameAsApp),
            (AppBrightness.system, AppStrings.themeBrightnessSystem),
            (AppBrightness.day, AppStrings.themeBrightnessDay),
            (AppBrightness.night, AppStrings.themeBrightnessNight),
          ],
          onChanged: (brightness) => unawaited(
            _set(
              brightness == null
                  ? look.copyWith(clearBrightness: true)
                  : look.copyWith(brightness: brightness),
            ),
          ),
        ),
        _fonts(look),
        _size(look),
        const SizedBox(height: 8),
      ],
    );
  }

  /// A row picking one of [options], each a value and what it reads as.
  Widget _choice<T>({
    required Key key,
    required String title,
    required T value,
    required List<(T, String)> options,
    required ValueChanged<T> onChanged,
  }) => ListTile(
    title: Text(title),
    trailing: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: key,
        value: value,
        onChanged: (picked) => onChanged(picked as T),
        items: [
          for (final (option, label) in options)
            DropdownMenuItem<T>(value: option, child: Text(label)),
        ],
      ),
    ),
  );

  /// The faces, each named in itself.
  Widget _fonts(EpubLook look) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.epubFontTitle,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final font in EpubFont.values)
              ChoiceChip(
                key: Key('epub-look-font-${font.name}'),
                label: Text(
                  epubFontLabel(font),
                  style: TextStyle(
                    fontFamily: epubFontFamily(font).family,
                    fontFamilyFallback: epubFontFamily(font).fallback,
                  ),
                ),
                selected: look.font == font,
                onSelected: (_) => unawaited(_set(look.copyWith(font: font))),
              ),
          ],
        ),
      ],
    ),
  );

  /// The text size, shown on the book as the slider moves.
  Widget _size(EpubLook look) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.epubTextSizeTitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(AppStrings.textScaleValue(look.textScale)),
          ],
        ),
        Slider(
          key: const Key('epub-look-size'),
          value: look.textScale,
          min: minTextScale,
          max: maxTextScale,
          divisions: _textScaleSteps,
          onChanged: (scale) => _preview(look.copyWith(textScale: scale)),
          onChangeEnd: (scale) =>
              unawaited(_set(look.copyWith(textScale: scale))),
        ),
      ],
    ),
  );
}
