// The app theme draws Material's controls for the surface (#1127): a
// pointer's theme (Windows, Linux) gets the compact IconButton, Checkbox,
// Slider, TextField and ListTile, a touch theme keeps Material's own.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/theme/palettes.dart';

void main() {
  /// The app theme as [platform] builds it. The platform is the theme's
  /// only input (adaptive density), so the override is dropped at once.
  ThemeData themeFor(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    try {
      return buildAppTheme(
        const BuiltinAppTheme(AppPalette.niman),
        Brightness.light,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<void> pumpControls(WidgetTester tester, ThemeData theme) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                key: const Key('icon'),
                onPressed: () {},
                icon: const Icon(Icons.add),
              ),
              Checkbox(key: const Key('check'), value: true, onChanged: (_) {}),
              Slider(key: const Key('slider'), value: 0.5, onChanged: (_) {}),
              const TextField(key: Key('field')),
              const ListTile(key: Key('tile'), title: Text('Row')),
            ],
          ),
        ),
      ),
    );
  }

  /// The size of each control under [theme].
  Future<Map<String, Size>> measure(
    WidgetTester tester,
    ThemeData theme,
  ) async {
    // A fresh tree, so nothing carries over from the previous theme.
    await tester.pumpWidget(const SizedBox());
    await pumpControls(tester, theme);
    // MaterialApp animates a theme change; the sizes are the settled ones.
    await tester.pumpAndSettle();
    return {
      for (final key in ['icon', 'check', 'slider', 'field', 'tile'])
        key: tester.getSize(find.byKey(Key(key))),
    };
  }

  testWidgets('a pointer theme draws the compact controls', (tester) async {
    final app = themeFor(TargetPlatform.windows);
    final plain = await measure(tester, ThemeData());
    final sizes = await measure(tester, app);
    expect(sizes['icon']!.height, lessThan(plain['icon']!.height));
    expect(sizes['check']!.height, lessThan(plain['check']!.height));
    expect(sizes['slider']!.height, lessThan(plain['slider']!.height));
    expect(sizes['field']!.height, lessThan(plain['field']!.height));
    expect(sizes['field']!.height, greaterThanOrEqualTo(32));
    expect(sizes['tile']!.height, lessThan(plain['tile']!.height));
    final slider = SliderTheme.of(
      tester.element(find.byKey(const Key('slider'))),
    );
    expect(slider.trackHeight, 3);
  });

  testWidgets('a touch theme keeps the Material controls', (tester) async {
    final app = themeFor(TargetPlatform.android);
    final plain = await measure(tester, ThemeData());
    expect(await measure(tester, app), plain);
    expect(plain['icon'], const Size(48, 48));
  });
}
