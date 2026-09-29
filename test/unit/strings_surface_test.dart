// The string contract (T-L10N-01) has no compiler check that a member is
// ever read: a key added for a screen that was never built — or left behind
// when the screen changed — compiles, ships in all thirty-seven locale
// files and says nothing. Fourteen did until #498.
//
// A key counts as read when its name appears outside the locale files: in
// any source of the app, or inside the facade for something other than its
// own forwarding. The facade is what hides a dead key — `static String get
// x => _s.x;` names it twice, once to declare it and once to call it — so a
// key whose mentions outside the locales are exactly that has nothing left
// reading it.
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

/// The text of every first-party source the app reads a key from.
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
  return <String>[for (final file in files) file.readAsStringSync()];
}

void main() {
  test('every key the contract declares is read somewhere', () {
    final keys = declaredKeys();
    expect(keys.length, greaterThan(1000), reason: 'the contract parsed');

    final sources_ = sources();
    expect(sources_.length, greaterThan(400), reason: 'the sources were read');
    final facade = _facade.readAsStringSync();

    final dead = <String>[];
    for (final key in keys) {
      final name = RegExp('\\b$key\\b');
      if (sources_.any(name.hasMatch)) continue;
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
