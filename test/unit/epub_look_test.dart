// How the books look (#280): four device settings of the library, read
// the settings file's way — a value nobody can read is the default.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_look.dart';

void main() {
  test('a fresh library reads its books in Literata, in the app colors', () {
    const look = EpubLook();
    expect(LibraryConfig.defaults.epubLook, look);
    expect(look.theme, isNull);
    expect(look.brightness, isNull);
    expect(look.font, EpubFont.literata);
    expect(look.textScale, defaultTextScale);
  });

  test('a look goes to the settings and back', () {
    const look = EpubLook(
      theme: 'custom:abc',
      brightness: AppBrightness.night,
      font: EpubFont.serif,
      textScale: 1.25,
    );
    expect(look.toJson(), {
      EpubLook.themeKey: 'custom:abc',
      EpubLook.brightnessKey: 'night',
      EpubLook.fontKey: 'serif',
      EpubLook.textScaleKey: 1.25,
    });
    expect(EpubLook.fromJson(look.toJson()), look);
    final config = LibraryConfig.defaults.copyWith(epubLook: look);
    expect(LibraryConfig.fromJsonMap(config.toJsonMap()), config);
  });

  test('the app theme and brightness are left out of the settings', () {
    final json = const EpubLook().toJson();
    expect(json.containsKey(EpubLook.themeKey), isFalse);
    expect(json.containsKey(EpubLook.brightnessKey), isFalse);
  });

  test('what cannot be read is the default, a size the nearest end', () {
    final look = EpubLook.fromJson(const {
      EpubLook.themeKey: 7,
      EpubLook.brightnessKey: 'dusk',
      EpubLook.fontKey: 'comic',
      EpubLook.textScaleKey: 9,
    });
    expect(look.theme, isNull);
    // An unknown brightness is the system's, as the app's own is.
    expect(look.brightness, AppBrightness.system);
    expect(look.font, EpubFont.literata);
    expect(look.textScale, maxTextScale);
  });

  test('clearing the theme and brightness puts back the app ones', () {
    const look = EpubLook(theme: 'gruvbox', brightness: AppBrightness.day);
    final cleared = look.copyWith(clearTheme: true, clearBrightness: true);
    expect(cleared.theme, isNull);
    expect(cleared.brightness, isNull);
  });

  test('the look stays on the device', () {
    // A size set on a phone means nothing on a desktop, and a custom
    // theme lives on the device that made it.
    final config = LibraryConfig.defaults.copyWith(
      epubLook: const EpubLook(theme: 'gruvbox', font: EpubFont.mono),
    );
    for (final key in EpubLook.keys) {
      expect(LibraryConfig.deviceKeys, contains(key));
      expect(config.libraryJsonMap().containsKey(key), isFalse);
    }
    expect(config.deviceJsonMap()[EpubLook.themeKey], 'gruvbox');
    expect(config.deviceJsonMap()[EpubLook.fontKey], 'mono');
  });
}
