// What scrolling a note whose bulk is a fitted table costs (#722).
//
// The device trace that opened this case: on Android, a 6.8 KB note — one
// heading, then a four-column table whose cells are long prose, 24 rows —
// laid out for 95–113 ms on the frames that brought its rows back into view,
// with `build 0.0 ms, paint ~1 ms` and `raster 2–7 ms` beside them. Not
// `LiveTables` measuring again: a row that leaves the window and comes back
// is drawn from the pieces it was measured into (`LiveTableRow.wrapped` is
// worked out once). It was a theme rebuilt per `build` (`markdownThemeOf`)
// handed to a cache kept by identity, so every rebuild dropped the
// measurements and took the whole table's again — 944 text painters each
// time for this note, ~265 ms on the device at open and ~100 ms a rebuild
// after (#722's own fix, on `fix/issue-722-theme`).
//
// What this case holds, then, is two claims. The one that holds on any host
// is the work: the rows that come back measure nothing again — the pieces
// that a report of re-measuring would point at are already there. The other
// is the frame that draws them: the steps of both legs are printed, and the
// *median* one is held to a 60 Hz frame under `NIMAN_PERF=1` alone, since a
// shared runner reads different milliseconds for the same commit
// (`AGENTS.md`). The worst is printed too: the first step of each leg builds
// the rows it brings in, and that step — 51 ms on this host, 265 ms at the
// device's open — is what is left of the case.
//
// Roboto is loaded from the Flutter cache when it is there, so the rows are
// measured with the font the device measured them with; without it the test
// still runs, on the test font, and the printed number is not comparable.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The bar a scroll step is held to under `NIMAN_PERF`: a 60 Hz frame, the
/// budget the read pane's frames are held to (`docs/records/huge-notes.md`).
const int _frameBarMicros = 16 * 1000;

/// The backstop every run keeps: a step this slow would hitch on any host.
const int _backstopMicros = 150 * 1000;

bool _roboto = false;

MarkdownTheme? _built;

/// One theme for the whole test: [LiveTables] keeps its measurements by the
/// theme's identity, and a theme built during a frame would drop them.
MarkdownTheme get _theme => _built ??= MarkdownTheme(
  body: TextStyle(
    fontSize: 14,
    height: 1.5,
    fontFamily: _roboto ? 'Roboto' : null,
  ),
  heading1: TextStyle(fontSize: 25, fontFamily: _roboto ? 'Roboto' : null),
  heading2: const TextStyle(fontSize: 21),
  heading3: const TextStyle(fontSize: 18),
  heading4: const TextStyle(fontSize: 16),
  heading5: const TextStyle(fontSize: 14),
  heading6: const TextStyle(fontSize: 13),
  code: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: const TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14, fontFamily: _roboto ? 'Roboto' : null),
  tableHeader: TextStyle(fontSize: 14, fontFamily: _roboto ? 'Roboto' : null),
  link: const TextStyle(fontSize: 14),
  wikilink: const TextStyle(fontSize: 14),
  tag: const TextStyle(fontSize: 14),
  marker: const TextStyle(fontSize: 14),
  codeHighlight: const <String, TextStyle>{},
  rule: const Color(0xFF888888),
  codeBackground: const Color(0xFFEEEEEE),
  quoteBar: const Color(0xFFCCCCCC),
  tableBorder: const Color(0xFFCCCCCC),
  markerDim: const Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: const EdgeInsets.all(4),
  lineHeight: 21,
);

/// The reporting note's shape (#722): a heading, then a four-column table
/// whose cells are long prose, [rows] rows of it, 6.8 KB at 24.
String _note(int rows) {
  final out = StringBuffer()
    ..writeln('# Fanfiction')
    ..writeln()
    ..writeln('| Titolo | Riassunto | Note | Link |')
    ..writeln('|---|---|---|---|');
  for (var at = 0; at < rows; at++) {
    out.writeln(
      '| [Storia $at](https://example.com/$at) '
      '| Una storia lunga con parecchie parole ${'parola $at ' * 5} '
      '| Alcune note di lettura, un commento e ${'dettaglio $at ' * 4} '
      '| https://example.com/altro/$at |',
    );
  }
  return out.toString();
}

void main() {
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) return;
    final font = File(
      '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    if (!font.existsSync()) return;
    final loader = FontLoader(
      'Roboto',
    )..addFont(font.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
    await loader.load();
    _roboto = true;
  });

  testWidgets('a fitted table, scrolled out and back, is not measured '
      'again', (tester) async {
    final buffer = SourceBuffer.fromText(_note(24));
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: buffer,
            mode: MarkdownSurfaceMode.live,
            theme: _theme,
          ),
        ),
      ),
    );
    await tester.pump();
    // Everything the first frame pays: every cell of the table measured, and
    // every row's widest word, because the table is wider than the pane.
    print(
      'first frame: ${LiveTables.measurements} measurements, '
      '${LiveTables.rowsLaid} rows laid out',
    );

    Future<List<int>> leg(double dy, int steps) async {
      final times = <int>[];
      for (var at = 0; at < steps; at++) {
        final clock = Stopwatch()..start();
        await tester.drag(find.byType(MarkdownSourceView), Offset(0, dy));
        await tester.pump();
        clock.stop();
        times.add(clock.elapsedMicroseconds);
      }
      return times;
    }

    void report(String name, List<int> times) {
      final sorted = [...times]..sort();
      final total = times.fold<int>(0, (sum, t) => sum + t);
      print(
        '$name: total ${total ~/ 1000} ms, '
        'median ${sorted[sorted.length ~/ 2] ~/ 1000} ms, '
        'worst ${sorted.last ~/ 1000} ms '
        '(${times.map((t) => t ~/ 1000).join(', ')})',
      );
    }

    // Down through the table, then back to the top: the way the report
    // scrolled, and the way the rows leave and come back.
    final down = await leg(-200, 12);
    final measuredDown = LiveTables.measurements;
    final laidDown = LiveTables.rowsLaid;
    final up = await leg(200, 12);
    report('down', down);
    report('up', up);
    print(_roboto ? 'Roboto' : 'test font');

    // The rows that come back are the rows that left: their pieces were
    // measured into the row, and no frame measures them again (#722).
    expect(
      LiveTables.measurements,
      measuredDown,
      reason: 'a row that came back was measured again',
    );
    expect(
      LiveTables.rowsLaid,
      laidDown,
      reason: 'a row that came back was laid out again',
    );

    for (final time in [...down, ...up]) {
      expect(
        time,
        lessThan(_backstopMicros),
        reason: 'a scroll step took ${time ~/ 1000} ms: the shape of #722',
      );
    }
    for (final leg in [down, up]) {
      final sorted = [...leg]..sort();
      final median = sorted[sorted.length ~/ 2];
      if (_referenceHost && _roboto) {
        expect(
          median,
          lessThan(_frameBarMicros),
          reason: 'the median scroll step missed a 60 Hz frame',
        );
      } else {
        expect(median, lessThan(_backstopMicros));
      }
    }
  });
}
