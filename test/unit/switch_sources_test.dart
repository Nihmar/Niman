// Every switch is drawn for the device (#1125): Material's `Switch` is a
// 52 x 32 touch control in a 48 px target, and no theme can shrink it, so
// every switch in the app is `AppSwitch` (or the row `AppSwitchListTile`).
// A raw one would stand phone-sized on a desktop beside them.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('no screen builds a raw Switch or SwitchListTile', () {
    final raw = RegExp(r'(?<![A-Za-z])Switch(ListTile|\.adaptive)?\(');
    const shared = {'app_switch.dart'};
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (shared.contains(p.basename(entity.path))) continue;
      final lines = entity.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'use AppSwitch / AppSwitchListTile');
  });
}
