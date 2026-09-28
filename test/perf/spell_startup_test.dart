// What the spell checker costs the frame that opens a note (#453).
//
// The cost is the dictionary, and all of it is inside `Hunspell_create`:
// measured on the reference host (Linux, libhunspell 1.7, a 540 KB `en_US`
// under `~/.local/share/dictionaries`, 2026-09-28) the load is ~16 ms,
// against ~0.4 ms for the ask that used to pay it, and ~0.03 ms a line for
// the words themselves, whatever their count. The frame that first asked a
// note for its ranges used to be the frame that parsed the dictionary: the
// state now starts the load on an isolate of its own where the library
// opens, and an ask that arrives first is answered "nothing yet" and asked
// again when the load notifies (#453).
//
// Same shape as the other benchmarks in this repository: the numbers are
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/spell_startup_test.dart`.
//
// Both of the asserted bars are the *load's* own quarter, so they read the
// same on any runner and they fail on the shape this fixes: an ask that
// carries the load reads at least the load.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/hunspell_spell_checker.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// Whether the host has hunspell and a dictionary at all: without them there
/// is no load to measure.
final bool _hasHunspell = () {
  final checker = HunspellSpellChecker.open();
  if (checker == null) return false;
  checker.dispose();
  return true;
}();

/// How many lines of a screen the checker is asked about, worst case: a
/// desktop window of a dense note.
const int _screen = 60;

/// How long this machine's dictionary costs to load, as `Hunspell_create`
/// charges it: the bar every assertion here is a fraction of.
final double _loadMs = _best(3, () => HunspellSpellChecker.open()?.dispose());

/// The best of [runs] timings of [body], in milliseconds.
double _best(int runs, void Function() body) {
  var best = double.infinity;
  for (var run = 0; run < runs; run++) {
    final ms = _once(body);
    if (ms < best) best = ms;
  }
  return best;
}

/// One timing of [body], in milliseconds: for the costs paid once, where a
/// best-of would measure the very cache the first call filled.
double _once(void Function() body) {
  final clock = Stopwatch()..start();
  body();
  clock.stop();
  return clock.elapsedMicroseconds / 1000;
}

/// A note's line, [index] included so no verdict is a cache hit: prose with
/// one typo, a piece of code and a link, as a real note has.
String _line(int index) =>
    'Line $index has a wrold in it, and `code($index)` is not prose.';

/// How long [check] took to have an engine, waiting on the state rather than
/// on any mechanism: what the app pays for the load, off the frame, noticed
/// only through the notification that follows it.
Future<double> _landed(EditorSpellCheck check) async {
  final clock = Stopwatch()..start();
  for (var round = 0; round < 500 && !check.available; round++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  clock.stop();
  return clock.elapsedMicroseconds / 1000;
}

void main() {
  test(
    'the dictionary load, and the frame that first asks for ranges',
    () async {
      // The load itself: what `Hunspell_create` costs over this machine's
      // dictionary, and what the frame used to pay at once.
      final load = _loadMs;

      // The frame the editor first draws a note on: it asks about its first
      // visible line, and must not be the frame that loads. The first ask,
      // timed once — every ask after it is a cache hit either way.
      final check = EditorSpellCheck();
      addTearDown(check.dispose);
      final ask = _once(
        () => check.rangesFor(0, _line(0), skip: const <TextRange>[]),
      );
      final landed = await _landed(check);

      // The backstop is the load's own quarter, which holds on any runner.
      // The ceiling is the design's — an ask is a field read while the load is
      // in flight.
      final bar = _referenceHost ? 1.0 : load / 4 + 0.5;
      print(
        'dictionary: ${load.toStringAsFixed(1)} ms to load, landed '
        '${landed.toStringAsFixed(1)} ms off the frame | first ask: '
        '${ask.toStringAsFixed(3)} ms (held to ${bar.toStringAsFixed(3)} ms)',
      );
      expect(ask, lessThan(bar));
      // And the load did land, with the typo marked: the ask above is cheap
      // because it waits for this, not because the checker gave up (#453).
      expect(check.available, isTrue);
      expect(
        check.rangesFor(0, _line(0), skip: const <TextRange>[]),
        hasLength(1),
      );
    },
    skip: _hasHunspell ? null : 'hunspell or a dictionary is not installed',
  );

  test('a screen of lines, once the dictionary is loaded', () async {
    final check = EditorSpellCheck();
    addTearDown(check.dispose);
    await _landed(check);
    expect(
      check.available,
      isTrue,
      reason: 'the load landed: this measures the checker, not its absence',
    );

    final clock = Stopwatch()..start();
    var found = 0;
    for (var line = 0; line < _screen; line++) {
      found += check
          .rangesFor(line, _line(line), skip: const <TextRange>[])
          .length;
    }
    clock.stop();
    final ms = clock.elapsedMicroseconds / 1000;

    // One typo a line, every one of them found: the number measures a pass
    // that did its work. A line's words are 0.07 ms here against the 16 ms
    // frame, because the pass is bounded by what is visible — the editor
    // asks the lines it lays out and nothing else.
    const ceiling = 12.0;
    const backstop = 90.0;
    final bar = _referenceHost ? ceiling : backstop;
    print(
      'a screen of $_screen lines: ${ms.toStringAsFixed(2)} ms '
      '(${(ms / _screen).toStringAsFixed(3)} ms a line, $found typos) '
      '(held to $bar ms)',
    );
    expect(found, _screen);
    expect(ms, lessThan(bar));
  }, skip: _hasHunspell ? null : 'hunspell or a dictionary is not installed');

  test(
    'a library opening its personal words does not load the engine again',
    () async {
      // A library opens its personal dictionary after the state exists (#60).
      // It used to drop the engines and load another dictionary on the next
      // ask — a stall of the same size, at the same kind of moment (#453).
      final dir = Directory.systemTemp.createTempSync('niman-spell-perf');
      addTearDown(() => dir.deleteSync(recursive: true));
      final words = await PersonalDictionary.open(dir.path);
      final check = EditorSpellCheck();
      addTearDown(check.dispose);
      await _landed(check);

      final clock = Stopwatch()..start();
      check.setPersonalDictionary(words);
      clock.stop();
      final swap = clock.elapsedMicroseconds / 1000;
      // The ask right after the library opened its words: the one that used
      // to be answered by loading the dictionary again.
      final ask = _once(
        () => check.rangesFor(0, _line(0), skip: const <TextRange>[]),
      );

      final bar = _referenceHost ? 1.0 : _loadMs / 4 + 0.5;
      print(
        'a personal dictionary attached: ${swap.toStringAsFixed(3)} ms, the '
        'ask after it: ${ask.toStringAsFixed(3)} ms (held to '
        '${bar.toStringAsFixed(3)} ms)',
      );
      expect(check.available, isTrue, reason: 'the engine stood');
      expect(ask, lessThan(bar));
    },
    skip: _hasHunspell ? null : 'hunspell or a dictionary is not installed',
  );
}
