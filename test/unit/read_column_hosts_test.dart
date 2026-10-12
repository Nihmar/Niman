import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_list.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/columns_run.dart';
import 'package:niman/src/markdown/render/read_column_hosts.dart';
import 'package:niman/src/markdown/source_buffer.dart';

const String _columns = '''
:::: columns
::: column
Left
:::

::: column
Right
:::
::::''';

/// A note of [before] paragraphs, the columns, and [after] paragraphs.
SourceBuffer _note(int before, int after) => SourceBuffer.fromText(
  [
    for (var at = 0; at < before; at++) 'before $at\n',
    _columns,
    for (var at = 0; at < after; at++) '\nafter $at',
  ].join('\n'),
);

List<int> _layOut(
  ReadColumnHosts hosts,
  SourceBuffer buffer, {
  List<FlagSpan>? previous,
}) => hosts.layOut(
  BlockScanner(buffer).index.blocks,
  buffer.lineAt,
  width: 800,
  em: 14,
  listIndent: 22,
  enabled: true,
  rawEstimate: (_) => 20,
  previous: previous,
);

void main() {
  test("the block list's fence lines find the runs a walk finds", () {
    final buffer = _note(3000, 3000);
    final blocks = BlockScanner(buffer).index.blocks as BlockList;
    final fenced = ColumnsRun.of(
      blocks,
      buffer.lineAt,
      fences: blocks.divIndices,
    );
    final walked = ColumnsRun.of(blocks, buffer.lineAt);
    expect(fenced, hasLength(1));
    expect(
      fenced.map((run) => (run.start, run.end, run.columns.length)),
      walked.map((run) => (run.start, run.end, run.columns.length)),
    );
  });

  test('a side-by-side run is a host span and a hosted one', () {
    final buffer = _note(2, 0);
    final hosts = ReadColumnHosts();
    final changed = _layOut(hosts, buffer);
    final run = hosts.sideBySide.single;
    expect(hosts.flags, <FlagSpan>[
      (start: run.start, end: run.start + 1, flag: ReadColumnHosts.host),
      (start: run.start + 1, end: run.end, flag: ReadColumnHosts.hosted),
    ]);
    expect(changed, [for (var at = run.start; at < run.end; at++) at]);
    expect(hosts.flagOf(run.start - 1), ReadColumnHosts.ordinary);
    expect(hosts.flagOf(run.end), ReadColumnHosts.ordinary);
    // Laid out again as it was, nothing changed.
    expect(_layOut(hosts, buffer, previous: hosts.flags), isEmpty);
  });

  test('an edit moves the spans, its own entries ordinary', () {
    final hosts = ReadColumnHosts()
      ..flags = const <FlagSpan>[
        (start: 5, end: 6, flag: ReadColumnHosts.host),
        (start: 6, end: 10, flag: ReadColumnHosts.hosted),
      ];
    // Entry 7 replaced by three.
    expect(hosts.spliced(7, 1, 3), <FlagSpan>[
      (start: 5, end: 6, flag: ReadColumnHosts.host),
      (start: 6, end: 7, flag: ReadColumnHosts.hosted),
      (start: 10, end: 12, flag: ReadColumnHosts.hosted),
    ]);
    // An entry more above the block.
    expect(hosts.spliced(0, 1, 2), <FlagSpan>[
      (start: 6, end: 7, flag: ReadColumnHosts.host),
      (start: 7, end: 11, flag: ReadColumnHosts.hosted),
    ]);
    // Below it, nothing moves.
    expect(hosts.spliced(12, 1, 0), hosts.flags);
  });
}
