/// How the library's books look (#280): their own theme, brightness, font
/// and text size, apart from the notes'.
///
/// Device settings of the library, kept per library as the note text size
/// is: a size picked on a phone means nothing on a desktop, and a custom
/// theme lives on the device that made it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/theme.dart';

/// The typefaces a book can be set in.
enum EpubFont {
  /// Literata, the reading face the app ships (SIL OFL): the same on every
  /// platform.
  literata,

  /// The platform's serif.
  serif,

  /// The app's own face, the one the notes are read in.
  sans,

  /// The platform's monospace.
  mono;

  /// The font with this [name]; anything unknown is [literata].
  static EpubFont fromName(Object? name) {
    for (final font in values) {
      if (font.name == name) return font;
    }
    return literata;
  }
}

/// How the books look.
@immutable
final class EpubLook {
  /// A look; the defaults are a fresh library's: the app's colors, Literata
  /// at the shipped size.
  const new({
    this.theme,
    this.brightness,
    this.font = EpubFont.literata,
    this.textScale = defaultTextScale,
  });

  /// Reads the four keys out of the library's settings. A value that is
  /// missing or of the wrong type reads as the default, a size out of range
  /// as the nearest end of it.
  factory fromJson(Map<String, Object?> json) {
    final theme = json[themeKey];
    final brightness = json[brightnessKey];
    return EpubLook(
      theme: theme is String && theme.isNotEmpty ? theme : null,
      brightness: brightness is String
          ? AppBrightness.fromId(brightness)
          : null,
      font: EpubFont.fromName(json[fontKey]),
      textScale: normalizeTextScale(json[textScaleKey]),
    );
  }

  /// The settings keys.
  static const String themeKey = 'epubTheme';

  /// See [themeKey].
  static const String brightnessKey = 'epubBrightness';

  /// See [themeKey].
  static const String fontKey = 'epubFont';

  /// See [themeKey].
  static const String textScaleKey = 'epubTextScale';

  /// Every key, for the settings' known and device key lists.
  static const Set<String> keys = {
    themeKey,
    brightnessKey,
    fontKey,
    textScaleKey,
  };

  /// The id of the theme the books wear (`AppTheme.id`), or null for the
  /// app's.
  final String? theme;

  /// How bright the books are, or null for as bright as the app.
  final AppBrightness? brightness;

  /// The face the books are set in.
  final EpubFont font;

  /// The books' text size, as a multiplier of the shipped one.
  final double textScale;

  /// A copy with the given fields replaced; [clearTheme] and
  /// [clearBrightness] put those back to the app's.
  EpubLook copyWith({
    String? theme,
    bool clearTheme = false,
    AppBrightness? brightness,
    bool clearBrightness = false,
    EpubFont? font,
    double? textScale,
  }) => EpubLook(
    theme: clearTheme ? null : theme ?? this.theme,
    brightness: clearBrightness ? null : brightness ?? this.brightness,
    font: font ?? this.font,
    textScale: textScale ?? this.textScale,
  );

  /// The keys as the settings hold them; the app's theme and brightness
  /// are left out.
  Map<String, Object?> toJson() => {
    if (theme != null) themeKey: theme,
    if (brightness != null) brightnessKey: brightness!.id,
    fontKey: font.name,
    textScaleKey: textScale,
  };

  @override
  bool operator ==(Object other) =>
      other is EpubLook &&
      other.theme == theme &&
      other.brightness == brightness &&
      other.font == font &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(theme, brightness, font, textScale);
}
