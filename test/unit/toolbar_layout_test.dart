// T-TB-01/02: the toolbar catalogue and the layout the user's order and
// hidden buttons are stored as.
import 'package:copist/src/editor/toolbar_item.dart';
import 'package:copist/src/editor/toolbar_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolbarItem', () {
    test('ids and widget keys are unique, and ids round-trip', () {
      final ids = <String>{};
      final keys = <Key>{};
      for (final item in ToolbarItem.values) {
        expect(ids.add(item.id), isTrue, reason: 'duplicate id ${item.id}');
        expect(keys.add(item.widgetKey), isTrue, reason: '${item.id} key');
        expect(ToolbarItem.fromId(item.id), item);
      }
      expect(ToolbarItem.fromId('marquee'), isNull);
    });

    test('every button has a name', () {
      for (final item in ToolbarItem.values) {
        expect(item.label, isNotEmpty, reason: item.id);
      }
    });
  });

  group('ToolbarLayout', () {
    test('the default is every button, in catalogue order, all shown', () {
      expect(ToolbarLayout.defaults.order, ToolbarItem.values);
      expect(ToolbarLayout.defaults.visible, ToolbarItem.values);
      expect(ToolbarLayout.defaults.hidden, isEmpty);
    });

    test('an empty or absent value is the default', () {
      expect(
        ToolbarLayout.parse(null).encode(),
        ToolbarLayout.defaults.encode(),
      );
      expect(ToolbarLayout.parse('').encode(), ToolbarLayout.defaults.encode());
      expect(
        ToolbarLayout.parse('   ').encode(),
        ToolbarLayout.defaults.encode(),
      );
    });

    test('order and hidden survive a round trip', () {
      const stored = 'link,-bold,italic';
      final layout = ToolbarLayout.parse(stored);
      expect(layout.order.take(3), [
        ToolbarItem.link,
        ToolbarItem.bold,
        ToolbarItem.italic,
      ]);
      expect(layout.hidden, {ToolbarItem.bold});
      expect(layout.visible.take(2), [ToolbarItem.link, ToolbarItem.italic]);
      expect(layout.encode().startsWith(stored), isTrue);
      expect(ToolbarLayout.parse(layout.encode()).encode(), layout.encode());
    });

    test('an unknown id is dropped and a missing one is appended shown', () {
      final layout = ToolbarLayout.parse('marquee,-bold');
      expect(layout.order.first, ToolbarItem.bold);
      expect(layout.order.length, ToolbarItem.values.length);
      expect(layout.hidden, {ToolbarItem.bold});
      // Everything the stored value never mentioned is visible.
      for (final item in ToolbarItem.values) {
        if (item != ToolbarItem.bold) expect(layout.isVisible(item), isTrue);
      }
    });

    test('a duplicated id is kept once', () {
      final layout = ToolbarLayout.parse('bold,bold,italic');
      expect(layout.order.where((i) => i == ToolbarItem.bold).length, 1);
      expect(layout.order.length, ToolbarItem.values.length);
    });

    test('hiding and showing a button leaves its place alone', () {
      final hidden = ToolbarLayout.defaults.withVisible(
        ToolbarItem.italic,
        visible: false,
      );
      expect(hidden.visible.contains(ToolbarItem.italic), isFalse);
      expect(hidden.order, ToolbarLayout.defaults.order);

      final shown = hidden.withVisible(ToolbarItem.italic, visible: true);
      expect(shown.visible, ToolbarItem.values);
    });

    test('reordering moves one button', () {
      final moved = ToolbarLayout.defaults.reorderedItem(0, 2);
      expect(moved.order[0], ToolbarItem.italic);
      expect(moved.order[1], ToolbarItem.strikethrough);
      expect(moved.order[2], ToolbarItem.bold);
      expect(moved.order.length, ToolbarItem.values.length);
    });
  });
}
