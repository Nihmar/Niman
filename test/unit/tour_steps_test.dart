// #266: the tour's step list — what it points at, and when a step is left
// out.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';

void main() {
  test('every step points at a target the app registers', () {
    final steps = tourSteps(canSwitchEditor: true, hasDock: true);
    expect(steps, isNotEmpty);
    for (final step in steps) {
      final target = step.target;
      if (target == null) continue;
      expect(
        TourTargets.all,
        contains(target),
        reason: '$target is not a target any widget registers',
      );
    }
  });

  test('the modes step goes when the source editor is off', () {
    final withSwitch = tourSteps(canSwitchEditor: true, hasDock: true);
    final without = tourSteps(canSwitchEditor: false, hasDock: true);

    expect(withSwitch.map((s) => s.target), contains(TourTargets.modeSwitch));
    expect(
      without.map((s) => s.target),
      isNot(contains(TourTargets.modeSwitch)),
    );
    expect(without, hasLength(withSwitch.length - 1));
  });

  test("the dock step is a wide window's", () {
    final narrow = tourSteps(canSwitchEditor: true, hasDock: false);
    final wide = tourSteps(canSwitchEditor: true, hasDock: true);

    expect(narrow.map((s) => s.target), isNot(contains(TourTargets.dock)));
    expect(wide.map((s) => s.target), contains(TourTargets.dock));
  });

  test('the last step hands the tour over to the cheatsheet', () {
    final steps = tourSteps(canSwitchEditor: true, hasDock: true);
    expect(steps.last.target, TourTargets.cheatsheet);
    expect(steps.last.action, TourAction.cheatsheet);
  });

  test('every step says something, and every id is used', () {
    final steps = tourSteps(canSwitchEditor: true, hasDock: true);
    for (final step in steps) {
      expect(step.title, isNotEmpty);
      expect(step.body, isNotEmpty);
    }
    expect(steps.map((s) => s.target).whereType<String>().toSet(), {
      TourTargets.tree,
      TourTargets.create,
      TourTargets.note,
      TourTargets.modeSwitch,
      TourTargets.toolbar,
      TourTargets.nav,
      TourTargets.dock,
      TourTargets.cheatsheet,
    });
  });
}
