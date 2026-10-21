// The screen kept on while slides are presented, on a Mac (#534): the power
// assertion is taken and let go, as the system's own pmset lists it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/keep_awake_mac.dart';

void main() {
  String assertions() =>
      Process.runSync('pmset', ['-g', 'assertions']).stdout as String;

  test('presenting holds the assertion, and ending lets it go', () {
    addTearDown(() => macKeepScreenOn(on: false));
    expect(macKeepScreenOn(on: true), isTrue);
    expect(assertions(), contains('Niman is presenting slides'));
    // Taking it again keeps the one already held.
    expect(macKeepScreenOn(on: true), isTrue);

    expect(macKeepScreenOn(on: false), isTrue);
    expect(assertions(), isNot(contains('Niman is presenting slides')));
  }, skip: Platform.isMacOS ? false : 'the power assertion is the Mac');
}
