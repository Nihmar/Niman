// #846: what a hovered link points at, read for a card — found by the rules
// following the link uses, read off the UI isolate and kept by the revision
// of the note, a dead link or a file that is not a note showing nothing.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/ui/link_preview/link_preview_body.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_link_source.dart';

void main() {
  group('previewOfLink', () {
    late FakeLinkSource source;

    setUp(() {
      source = FakeLinkSource(
        notes: [
          'Newton.md',
          'Notes/Optics.md',
          'a/Twin.md',
          'b/Twin.md',
          'pic.png',
          'Here.md',
        ],
      );
      source.previews['Newton.md'] = '# Newton\n\nText.\n';
      source.previews['Notes/Optics.md'] = 'Light.\n';
      source.previews['Here.md'] = 'Here.\n';
    });

    Future<LinkPreview?> wiki(String inner, {String? from = 'Here.md'}) =>
        previewOfLink(source, PreviewLink.wiki(inner), from: from);
    Future<LinkPreview?> md(String href, {String? from = 'Here.md'}) =>
        previewOfLink(source, PreviewLink.markdown(href), from: from);

    test('a wikilink shows its note, titled by its name', () async {
      final preview = (await wiki('Newton'))!;

      expect(preview.path, 'Newton.md');
      expect(preview.title, 'Newton');
      expect(preview.text, '# Newton\n\nText.\n');
      expect(preview.anchor, isNull);
      expect(preview.truncated, isFalse);
      expect((await wiki('Optics'))!.title, 'Optics');
    });

    test(
      'the heading, the path and the block ride along as the anchor',
      () async {
        expect((await wiki('Newton#Early life'))!.anchor, 'Early life');
        expect((await wiki('Newton#A#B|shown'))!.anchor, 'A#B');
        expect((await wiki('Newton#^37066d'))!.anchor, '^37066d');
      },
    );

    test('a Markdown link shows its note, and its fragment too', () async {
      expect((await md('Newton.md'))!.path, 'Newton.md');
      expect((await md('Newton.md#Part'))!.anchor, 'Part');
      expect((await md('Notes/Optics.md#^id'))!.anchor, '^id');
    });

    test('a link to nothing shows nothing: dead, ambiguous, a URL', () async {
      expect(await wiki('Nope'), isNull);
      expect(await wiki('Twin'), isNull, reason: 'two notes: which one?');
      expect(await md('missing.md'), isNull);
      expect(await md('https://example.com/x.md'), isNull);
      expect(await md('#heading'), isNull);
      expect(await wiki('#heading'), isNull);
      expect(await wiki('|alias'), isNull);
    });

    test('a file that is not a note shows no card', () async {
      source.previews['pic.png'] = 'binary';
      expect(await wiki('pic.png'), isNull);
    });

    test('a note links to itself, and the page is already on screen', () async {
      expect(await wiki('Here'), isNull);
      expect(await wiki('Newton', from: 'Newton.md'), isNull);
    });

    test('a note that cannot be read shows no card', () async {
      source.notes.add('Gone.md');
      expect(await wiki('Gone'), isNull);
    });

    test('a label-first link reads the aliased part as the note', () async {
      final preview = (await wiki('a label|Newton#Part'))!;
      expect(preview.path, 'Newton.md');
      expect(preview.anchor, 'Part');
      expect(await wiki('a label|nothing'), isNull);
    });
  });

  group('LinkResolver.previewText', () {
    late IndexDatabase db;
    late List<String> reads;
    late LinkResolver resolver;
    late Completer<void> gate;
    var held = false;

    Future<int> addNote(String path, {int size = 1, int modified = 0}) {
      return db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              path: path,
              parent: 0,
              name: path.split('/').last,
              isDir: false,
              size: size,
              modified: DateTime.fromMillisecondsSinceEpoch(modified * 1000),
              created: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
    }

    setUp(() {
      db = IndexDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      reads = <String>[];
      gate = Completer<void>();
      held = false;
      resolver = LinkResolver(
        db,
        readPreview: (path) async {
          reads.add(path);
          if (held) await gate.future;
          return path == 'Gone.md'
              ? null
              : NotePreviewText(text: 'text of $path', truncated: false);
        },
      );
    });

    test('is read once for a sweep of hovers over the same link', () async {
      await addNote('A.md');

      for (var hover = 0; hover < 5; hover++) {
        expect((await resolver.previewText('A.md'))!.text, 'text of A.md');
      }

      expect(reads, ['A.md']);
    });

    test('hovers that arrive while a read runs share it', () async {
      await addNote('A.md');
      held = true;

      final first = resolver.previewText('A.md');
      final second = resolver.previewText('A.md');
      await pumpEventQueue();
      gate.complete();

      expect((await first)!.text, (await second)!.text);
      expect(reads, ['A.md']);
    });

    test(
      "is keyed by the note's revision: a changed note is read again",
      () async {
        final id = await addNote('A.md', size: 10, modified: 5);
        await resolver.previewText('A.md');

        await (db.update(db.notes)..where((n) => n.id.equals(id))).write(
          NotesCompanion(
            size: const Value(11),
            modified: Value(DateTime.fromMillisecondsSinceEpoch(9000)),
          ),
        );
        await resolver.previewText('A.md');
        await resolver.previewText('A.md');

        expect(reads, ['A.md', 'A.md'], reason: 'once per revision');
      },
    );

    test(
      'keeps a bounded number of previews, the least recent going',
      () async {
        for (var i = 0; i < PreviewLimits.kept + 4; i++) {
          await addNote('n$i.md');
          await resolver.previewText('n$i.md');
        }
        expect(resolver.previewsHeld, PreviewLimits.kept);

        reads.clear();
        await resolver.previewText('n${PreviewLimits.kept + 3}.md');
        expect(reads, isEmpty, reason: 'the latest is still kept');
        await resolver.previewText('n0.md');
        expect(reads, ['n0.md'], reason: 'the first was let go');
      },
    );

    test(
      'a read that found nothing is not kept: the note may come back',
      () async {
        await addNote('Gone.md');
        expect(await resolver.previewText('Gone.md'), isNull);
        expect(await resolver.previewText('Gone.md'), isNull);
        expect(reads, ['Gone.md', 'Gone.md']);
        expect(resolver.previewsHeld, 0);
      },
    );

    test(
      'a note the index does not hold, or a source that reads none',
      () async {
        expect(await resolver.previewText('Nope.md'), isNull);
        await addNote('A.md');
        expect(await LinkResolver(db).previewText('A.md'), isNull);
        expect(reads, isEmpty);
      },
    );
  });

  group('previewTextOfNoteFile', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('niman_preview_');
      addTearDown(() => dir.delete(recursive: true));
    });

    String write(String name, List<int> bytes) {
      final path = p.join(dir.path, name);
      File(path).writeAsBytesSync(bytes);
      return path;
    }

    test('a short note is read whole, its line endings and BOM normalized', () {
      final path = write('a.md', [
        0xEF, 0xBB, 0xBF, // BOM
        ...'one\r\ntwo\rthree\n'.codeUnits,
      ]);

      final preview = previewTextOfNoteFile(path);

      expect(preview.text, 'one\ntwo\nthree\n');
      expect(preview.truncated, isFalse);
    });

    test('a long note is read to the limit and says it goes on', () {
      final line = '${'word ' * 20}\n';
      final text = line * (PreviewLimits.bytes ~/ line.length + 50);
      final path = write('long.md', text.codeUnits);

      final preview = previewTextOfNoteFile(path);

      expect(preview.truncated, isTrue);
      expect(preview.text.length, PreviewLimits.bytes);
      expect(text.startsWith(preview.text), isTrue);
    });

    test('a multi-byte character cut at the limit does not fail the read', () {
      final bytes = <int>[
        ...List.filled(PreviewLimits.bytes - 1, 0x61),
        ...[0xC3, 0xA9], // é, whose first byte is the last the read keeps
        ...List.filled(10, 0x62),
      ];
      final preview = previewTextOfNoteFile(write('cut.md', bytes));

      expect(preview.truncated, isTrue);
      expect(preview.text.startsWith('a' * 100), isTrue);
    });
  });

  group('anchorLineOf', () {
    const text = '# Top\n\n## A\n\npara one ^p1\n\n### C\n\nlast\n';

    test('a heading, a path and a block name their lines', () {
      expect(anchorLineOf(text, 'A'), 2);
      expect(anchorLineOf(text, 'A#C'), 6);
      expect(anchorLineOf(text, '^p1'), 4);
    });

    test('no anchor, or one the note lacks, names none', () {
      expect(anchorLineOf(text, null), isNull);
      expect(anchorLineOf(text, 'Nope'), isNull);
      expect(anchorLineOf(text, '^nope'), isNull);
      expect(anchorLineOf(text, ''), isNull);
    });
  });
}
