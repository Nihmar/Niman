// #536: the navigation's order and hidden destinations, by name — what a
// saved layout makes of the destinations a build has.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';

void main() {
  const defaults = ['files', 'todo', 'search', 'quicknote', 'settings'];

  List<String> visible(List<PlacedDestination> placed) => [
    for (final d in placed)
      if (!d.hidden) d.name,
  ];

  test('the empty layout is the defaults, all shown', () {
    expect(visible(const NavigationLayout().place(defaults)), defaults);
  });

  test('a saved order and hidden set are kept', () {
    const layout = NavigationLayout(
      order: ['search', 'files', 'todo', 'settings', 'quicknote'],
      hidden: {'todo'},
    );
    expect(visible(layout.place(defaults)), [
      'search',
      'files',
      'settings',
      'quicknote',
    ]);
  });

  test('a destination added since goes after its predecessor, hidden', () {
    const layout = NavigationLayout(
      order: ['search', 'files', 'todo', 'quicknote', 'settings'],
    );
    final placed = layout.place(
      ['files', 'todo', 'search', 'home', 'quicknote', 'settings'],
      defaultHidden: {'home'},
    );
    expect(
      [for (final d in placed) d.name],
      ['search', 'home', 'files', 'todo', 'quicknote', 'settings'],
    );
    expect(placed[1].hidden, isTrue);
  });

  test('an unknown name is left out, and kept for the build that knows it', () {
    const layout = NavigationLayout(
      order: ['study', 'files', 'todo', 'search', 'quicknote', 'settings'],
      hidden: {'study'},
    );
    final placed = layout.place(defaults);
    expect(visible(placed), defaults);
    final kept = layout.keep(placed);
    expect(kept.order.last, 'study');
    expect(kept.hidden, {'study'});
  });

  test('a locked destination is never hidden', () {
    const layout = NavigationLayout(order: defaults, hidden: {'settings'});
    expect(visible(layout.place(defaults, locked: {'settings'})), defaults);
  });

  test('round-trips through settings.json, and reads junk as defaults', () {
    const layout = NavigationLayout(
      order: ['todo', 'files', 'search', 'quicknote', 'settings'],
      hidden: {'search'},
    );
    expect(NavigationLayout.fromJson(layout.toJson()), layout);
    expect(NavigationLayout.fromJson('files'), const NavigationLayout());
    expect(
      NavigationLayout.fromJson(const {
        'order': ['files', 3],
        'hidden': null,
      }),
      const NavigationLayout(order: ['files']),
    );
  });

  test('the library travels, the device copy stays and wins', () {
    const shared = NavigationLayout(order: defaults, hidden: {'todo'});
    const mine = NavigationLayout(order: defaults, hidden: {'search'});
    final config = LibraryConfig.defaults.copyWith(
      navigation: shared,
      deviceNavigation: mine,
    );
    expect(config.libraryJsonMap()['navigation'], shared.toJson());
    expect(config.libraryJsonMap(), isNot(contains('deviceNavigation')));
    expect(config.deviceJsonMap()['deviceNavigation'], mine.toJson());
    final back = LibraryConfig.fromJsonMap(config.toJsonMap());
    expect(back, config);
    final following = back.copyWith(clearDeviceNavigation: true);
    expect(following.deviceNavigation, isNull);
    expect(following.navigation, shared);
  });

  test('the start round-trips, survives keep, and is absent by default', () {
    // #706: the destination the app opens on, by name.
    const layout = NavigationLayout(order: defaults, start: 'search');
    expect(NavigationLayout.fromJson(layout.toJson()), layout);
    expect(const NavigationLayout().toJson().containsKey('start'), isFalse);
    expect(layout.keep(layout.place(defaults)).start, 'search');
    expect(layout.withStart(null).start, isNull);
    expect(layout.withStart(null), isNot(layout));
    expect(NavigationLayout.fromJson(const {'start': 3}).start, isNull);
  });
}
