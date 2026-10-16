// #1013: the kinds a folder menu creates are one table, read by both menus.
// A table kept for the whole run must not keep its labels from the first
// read: they follow the language in use when a menu is built.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/ui/create_kinds.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  test('the labels follow a language change made after the first read', () {
    AppLanguages.choice = AppLanguage.english;
    final english = [for (final kind in createKinds) kind.label()];
    AppLanguages.choice = AppLanguage.italian;
    final italian = [for (final kind in createKinds) kind.label()];
    expect(italian, hasLength(english.length));
    for (var i = 0; i < english.length; i++) {
      expect(italian[i], isNot(english[i]), reason: createKinds[i].value);
    }
  });

  test('a menu choice names its kind', () {
    expect(createKindOf('audio')?.value, 'audio');
    expect(createKindOf('slides')?.value, 'slides');
    expect(createKindOf('flashcards')?.value, 'flashcards');
    expect(createKindOf('folder'), isNull);
    expect(createKindOf(null), isNull);
  });
}
