// A pointer's menus are compact by default (#296): a popup menu's row height
// and divider height are constructor arguments no theme reaches, so every
// menu is built through `menuItem`, `menuDivider` and `MenuRow`. A raw
// `PopupMenuItem` would stand 48 px tall on a desktop beside them.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('no menu builds a raw PopupMenuItem or PopupMenuDivider', () {
    final raw = RegExp(
      r'(?<![A-Za-z])(Checked)?Popup(MenuItem|MenuDivider)(<[^>(]*>)?\(',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (p.basename(entity.path) == 'pointer_menu.dart') continue;
      final lines = entity.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'use menuItem() / menuDivider()');
  });

  // Material's drop-downs take their rows' height as a constructor argument
  // and refuse one under 48 px (#1119): every choice is MenuChoiceButton.
  test('no control builds a Material drop-down', () {
    final raw = RegExp(
      '(?<![A-Za-z])(DropdownButton|DropdownButtonFormField|DropdownMenu|'
      r'DropdownMenuItem|DropdownButtonHideUnderline)(<[^>(]*>)?\(',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'use MenuChoiceButton');
  });
}
