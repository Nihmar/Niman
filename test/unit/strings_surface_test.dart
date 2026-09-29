// The string contract (T-L10N-01) has no compiler check that a member is
// ever read: a key added for a screen that was never built — or left behind
// when the screen changed — compiles, ships in all thirty-seven locale
// files and says nothing. Fourteen did until #498.
//
// A key counts as read when the code of the app says `AppStrings.<key>`, or
// when the facade uses it for something other than its own forwarding. A
// mention in a comment is not a read, and neither is a member of the same
// name on something else (`widget.settingsTitle`, an enum value): the first
// version of this test counted both, so a key documented in a comment, or
// sharing its name with a field, looked alive when nothing called it.
//
// The facade is what hides a dead key — `static String get x => _s.x;`
// names it twice, once to declare it and once to call it — so a key whose
// mentions in the facade are exactly that has nothing left reading it.
//
// Run from the package root, like `flutter test` does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The contract: one abstract member per label.
final _contract = File(p.join('lib', 'src', 'ui', 'strings', 'base.dart'));

/// The facade, which turns every one of them into `AppStrings.<name>`.
final _facade = File(p.join('lib', 'src', 'ui', 'strings.dart'));

/// The locale files, which implement them: one class per file.
final String _locales = p.join('lib', 'src', 'ui', 'strings') + p.separator;

/// The members the contract declares, in the order it declares them.
List<String> declaredKeys() {
  final declaration = RegExp(
    r'^\s{2}(?:List<String>|String)\s+(?:get\s+)?([a-zA-Z][A-Za-z0-9]*)\s*[;(]',
    multiLine: true,
  );
  return <String>[
    for (final match in declaration.allMatches(_contract.readAsStringSync()))
      match.group(1)!,
  ];
}

/// [source] without its comments: line comments, doc comments and block
/// comments (which nest in Dart). A `//` inside a string literal is text,
/// not a comment, so strings are walked whole.
String withoutComments(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final c = source[i];
    if (source.startsWith('//', i)) {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
    } else if (source.startsWith('/*', i)) {
      var depth = 1;
      i += 2;
      while (i < source.length && depth > 0) {
        if (source.startsWith('/*', i)) {
          depth++;
          i += 2;
        } else if (source.startsWith('*/', i)) {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && source[i - 1] == 'r';
      final quote = source.startsWith(c * 3, i) ? c * 3 : c;
      out.write(quote);
      i += quote.length;
      while (i < source.length && !source.startsWith(quote, i)) {
        if (source[i] == r'\' && !raw && i + 1 < source.length) {
          out.write(source[i]);
          i++;
        }
        out.write(source[i]);
        i++;
      }
      if (i < source.length) {
        out.write(quote);
        i += quote.length;
      }
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

/// Whether [code] reads [key] from the facade: `AppStrings.<key>`, with
/// nothing between the two, so `widget.<key>` is somebody else's member.
bool readsKey(String code, String key) =>
    RegExp('\\bAppStrings\\.$key\\b').hasMatch(code);

/// The code of every first-party source the app reads a key from.
///
/// The locale files are left out — a key's own implementation there reads
/// nothing — and the facade is asked separately, since all but its
/// forwarding counts.
List<String> sources() {
  final files = Directory(p.join('lib'))
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => p.extension(file.path) == '.dart')
      .where((file) => !file.path.startsWith(_locales))
      .where((file) => !p.equals(file.path, _facade.path));
  return <String>[
    for (final file in files) withoutComments(file.readAsStringSync()),
  ];
}

void main() {
  group('reading a key', () {
    test('a comment is not a read', () {
      final code = withoutComments('''
// AppStrings.settingsTitle in a line comment
/// AppStrings.settingsTitle in a doc comment
/* AppStrings.settingsTitle /* nested */ in a block comment */
final x = 1;
''');
      expect(readsKey(code, 'settingsTitle'), isFalse);
    });

    test('a member of the same name on something else is not a read', () {
      final code = withoutComments('final t = widget.settingsTitle;');
      expect(readsKey(code, 'settingsTitle'), isFalse);
      // Nor does a longer name stand in for the shorter one.
      expect(
        readsKey('AppStrings.settingsTitleLong', 'settingsTitle'),
        isFalse,
      );
    });

    test('a call in code is a read, and a `//` in a string is no comment', () {
      final code = withoutComments(
        "final a = launch('https://x.test'); "
        'final t = AppStrings.settingsTitle;',
      );
      expect(readsKey(code, 'settingsTitle'), isTrue);
      expect(
        readsKey(
          withoutComments(r"final t = '${AppStrings.settingsTitle}';"),
          'settingsTitle',
        ),
        isTrue,
      );
    });
  });

  test('every key the contract declares is read somewhere', () {
    final keys = declaredKeys();
    expect(keys.length, greaterThan(1000), reason: 'the contract parsed');

    final sources_ = sources();
    expect(sources_.length, greaterThan(400), reason: 'the sources were read');
    final facade = withoutComments(_facade.readAsStringSync());

    final dead = <String>[];
    for (final key in keys) {
      if (sources_.any((code) => readsKey(code, key))) continue;
      final name = RegExp('\\b$key\\b');
      final mentions = name.allMatches(facade).length;
      final forwarded = RegExp(
        '^\\s*static [^\\n]*\\b$key\\b',
        multiLine: true,
      ).hasMatch(facade);
      if (mentions > (forwarded ? 2 : 0)) continue;
      dead.add(key);
    }

    expect(
      dead,
      isEmpty,
      reason:
          'nothing in `lib/` reads these; drop them from the contract, '
          'the facade and every locale',
    );
  });
}
