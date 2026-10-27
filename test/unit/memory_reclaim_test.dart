// The registry that empties the rebuildable caches (#1195), and the observer
// that fires it on the system's call for memory and when the app is paused.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/memory_reclaim.dart';
import 'package:niman/src/core/memory_reclaim_observer.dart';
import 'package:niman/src/core/reclaimable.dart';

/// An owner that counts how often it was asked to give memory back.
final class _Owner implements Reclaimable {
  new({this.fails = false});

  /// Whether it throws when asked; a test that arms it disarms it after.
  bool fails;
  int reclaimed = 0;

  @override
  void reclaim() {
    reclaimed++;
    if (fails) throw StateError('cannot let go');
  }
}

/// A new owner, already tracked.
_Owner _trackedOwner() {
  final owner = _Owner();
  MemoryReclaim.track(owner);
  return owner;
}

/// [count] owners, each already tracked.
List<_Owner> _tracked(int count) => [
  for (var i = 0; i < count; i++) _trackedOwner(),
];

void main() {
  group('the registry', () {
    test('asks every tracked owner to give its memory back', () {
      final owners = _tracked(3);

      MemoryReclaim.reclaimAll();
      expect(owners.map((owner) => owner.reclaimed), [1, 1, 1]);

      MemoryReclaim.reclaimAll();
      expect(owners.map((owner) => owner.reclaimed), [2, 2, 2]);
    });

    test('says how many it asked', () {
      final before = MemoryReclaim.tracked;
      final owners = _tracked(2);

      expect(MemoryReclaim.tracked, before + 2);
      expect(MemoryReclaim.reclaimAll(), before + 2);
      expect(owners.map((owner) => owner.reclaimed), [1, 1]);
    });

    test('keeps every live owner through many, pruning as it grows', () {
      // Far past the first prune: the sweep must not lose a live owner.
      final owners = _tracked(500);

      MemoryReclaim.reclaimAll();

      expect(owners.every((owner) => owner.reclaimed == 1), isTrue);
      expect(MemoryReclaim.tracked, greaterThanOrEqualTo(owners.length));
    });

    testWidgets('an owner that throws does not keep the others', (
      tester,
    ) async {
      final broken = _Owner(fails: true);
      // The registry is the process's, and holds the owner until it is
      // collected — which a later test cannot count on: disarmed, it is an
      // owner like any other to the tests after this one.
      addTearDown(() => broken.fails = false);
      final fine = _Owner();
      MemoryReclaim.track(broken);
      MemoryReclaim.track(fine);

      MemoryReclaim.reclaimAll();
      // The failure is reported, not thrown; the test takes it.
      final error = tester.takeException();

      expect(error, isA<StateError>());
      expect(broken.reclaimed, 1);
      expect(fine.reclaimed, 1);
    });
  });

  group('the observer', () {
    late _Owner owner;
    late MemoryReclaimObserver observer;

    setUp(() {
      owner = _Owner();
      MemoryReclaim.track(owner);
      observer = MemoryReclaimObserver();
      TestWidgetsFlutterBinding.ensureInitialized().addObserver(observer);
    });

    tearDown(() {
      WidgetsBinding.instance.removeObserver(observer);
    });

    testWidgets('the system asking for memory empties the caches', (
      tester,
    ) async {
      tester.binding.handleMemoryPressure();

      expect(owner.reclaimed, 1);
    });

    testWidgets('going to the background empties them', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      expect(owner.reclaimed, 1);
    });

    testWidgets('the other lifecycle states leave them', (tester) async {
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(owner.reclaimed, 0);
    });

    testWidgets('install attaches one observer, once', (tester) async {
      MemoryReclaimObserver.install();
      MemoryReclaimObserver.install();

      tester.binding.handleMemoryPressure();

      // Once for the installed observer and once for the test's own: a
      // second install would have made it three.
      expect(owner.reclaimed, 2);
    });
  });
}
