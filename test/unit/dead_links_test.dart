// #847: which of a note's links name nothing — resolved in one batch against
// the index, judged at the note level only, and asked of a small value the
// drawing holds.
import 'dart:async';

import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/links/dead_link_checker.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/render/dead_link_ranges.dart';
import 'package:niman/src/ui/dead_link_watcher.dart';
import 'package:niman/src/ui/note_dead_links.dart';

import '../fakes/fake_link_source.dart';

void main() {
  late IndexDatabase db;
  late DeadLinkChecker resolver;

  Future<void> addNote(String path, {String? stem}) async {
    final id = await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            path: path,
            parent: 0,
            name: path.split('/').last,
            isDir: false,
            size: 1,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
            created: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
    final name = path.split('/').last;
    await db
        .into(db.noteStems)
        .insert(
          NoteStemsCompanion.insert(
            stem: stem ?? name.toLowerCase().replaceAll(RegExp(r'\.md$'), ''),
            noteId: id,
            source: 'file',
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  setUp(() async {
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    resolver = DeadLinkChecker(LinkResolver(db));
  });

  LinkQuery wiki(String target) =>
      (target: target, from: null, markdown: false);
  LinkQuery md(String href) => (target: href, from: null, markdown: true);

  group('DeadLinkChecker.deadAmong', () {
    test(
      'a wiki target with no note is dead, one with a note is not',
      () async {
        await addNote('Live.md');
        final dead = await resolver.deadAmong([wiki('Live'), wiki('Missing')]);
        expect(dead, {wiki('Missing')});
      },
    );

    test('case and the .md extension do not make a note dead', () async {
      await addNote('My Note.md');
      expect(
        await resolver.deadAmong([wiki('my note.MD'), wiki('MY NOTE')]),
        isEmpty,
      );
    });

    test('a name several notes share is ambiguous, not dead', () async {
      await addNote('a/Note.md');
      await addNote('b/Note.md');
      expect(await resolver.deadAmong([wiki('Note')]), isEmpty);
    });

    test(
      'a path that matches no note is dead, even with the stem there',
      () async {
        await addNote('a/Note.md');
        expect(await resolver.deadAmong([wiki('b/Note')]), {wiki('b/Note')});
      },
    );

    test(
      'a Markdown link is dead when its file is not in the library',
      () async {
        await addNote('docs/a.md');
        await addNote('Books/Dune.pdf', stem: 'dune.pdf');
        final dead = await resolver.deadAmong([
          md('docs/a.md'),
          md('docs/nope.md'),
          md('Books/Dune.pdf'),
          md('Books/Gone.pdf'),
          md('My%20Missing.md'),
        ]);
        expect(dead, {
          md('docs/nope.md'),
          md('Books/Gone.pdf'),
          md('My%20Missing.md'),
        });
      },
    );

    test(
      'a URL, an anchor and an href with no extension are never dead',
      () async {
        expect(
          await resolver.deadAmong([
            md('https://example.com/x.md'),
            md('#heading'),
            md('no-extension'),
            md(''),
            wiki(''),
            wiki('   '),
          ]),
          isEmpty,
        );
      },
    );

    test('a fragment is not asked: the note decides', () async {
      await addNote('Live.md');
      expect(
        await resolver.deadAmong([wiki('Live#Nope'), md('Live.md#nope')]),
        isEmpty,
        reason: 'the note exists; a heading it lacks does not make it dead',
      );
      expect(await resolver.deadAmong([wiki('Gone#Head')]), {
        wiki('Gone#Head'),
      });
    });

    test('many links are one batch of lookups', () async {
      for (var i = 0; i < 40; i++) {
        await addNote('n$i.md');
      }
      final queries = [for (var i = 0; i < 80; i++) wiki('n$i')];
      final dead = await resolver.deadAmong(queries);
      expect(dead, hasLength(40));
      expect(dead.every((q) => int.parse(q.target.substring(1)) >= 40), isTrue);
    });
  });

  group('DeadLinks', () {
    test(
      'a wikilink is dead when its target is, unless its alias is a note',
      () {
        const dead = DeadLinks(wiki: {'Gone', 'the idea'});
        expect(dead.wikiIsDead(parseWikiRef('Gone')), isTrue);
        expect(dead.wikiIsDead(parseWikiRef('Live')), isFalse);
        // A label-first link, `[[a label|filename]]`, reads the aliased part as
        // the note when the first part is none: dead only if that is none too.
        expect(dead.wikiIsDead(parseWikiRef('Gone|the idea')), isTrue);
        expect(
          dead.wikiIsDead(parseWikiRef('Gone|Live')),
          isFalse,
          reason: 'Live is not known dead: the link is drawn live',
        );
        expect(
          const DeadLinks(wiki: {'Gone'})
              .wikiIsDead(parseWikiRef('Gone|Alias')),
          isFalse,
          reason: 'an alias that was not asked is taken to be a note',
        );
      },
    );

    test('a link with no target is the note it is in, never dead', () {
      const dead = DeadLinks(wiki: {'Gone'});
      expect(dead.wikiIsDead(parseWikiRef('#Heading')), isFalse);
      expect(dead.wikiIsDead(parseWikiRef('|alias')), isFalse);
    });

    test('an href is asked as the set keeps it: trimmed, unangled', () {
      const dead = DeadLinks(href: {'my note.md'});
      expect(dead.hrefIsDead('my note.md'), isTrue);
      expect(dead.hrefIsDead(' <my note.md> '), isTrue);
      expect(dead.hrefIsDead('other.md'), isFalse);
    });

    test('two sets of the same targets are equal', () {
      expect(
        const DeadLinks(wiki: {'a', 'b'}),
        const DeadLinks(wiki: {'b', 'a'}),
      );
      expect(const DeadLinks(wiki: {'a'}), isNot(const DeadLinks(href: {'a'})));
      expect(DeadLinks.none.isEmpty, isTrue);
    });

    test('resolveDeadLinks asks each target once, aliases included', () async {
      await addNote('Live.md');
      final links = parseLinks(
        '[[Live]] [[Gone]] [[Gone|label]] [[x|Live]] [[Gone2|Also gone]] '
        '[t](missing.md) [u](Live.md) [v](https://x.y/z.md) ![[img.png]]',
      );
      final dead = await resolveDeadLinks(resolver, links, from: 'n.md');
      expect(dead.wiki, {'Gone', 'label', 'x', 'Gone2', 'Also gone'});
      expect(dead.href, {'missing.md'});
      // `[[x|Live]]` names the note `Live` through its alias: not dead.
      expect(dead.wikiIsDead(parseWikiRef('x|Live')), isFalse);
      expect(dead.wikiIsDead(parseWikiRef('Gone|label')), isTrue);
    });
  });

  group('deadLinkRanges', () {
    StyledLine line(String text) =>
        HighlightDocument.fromText(text).lines.single;

    test('a dead wikilink and a dead Markdown link are ranges of the line', () {
      const text =
          'See [[Gone]], [[Live]] and [x](missing.md) or [y](here.md).';
      const dead = DeadLinks(wiki: {'Gone'}, href: {'missing.md'});
      final ranges = deadLinkRanges(line(text), dead);
      expect(
        [for (final r in ranges) text.substring(r.start, r.end)],
        ['[[Gone]]', '[x](missing.md)'],
      );
    });

    test('a wikilink with a heading or an alias is judged by its target', () {
      const text = '[[Gone#Part|shown]] [[Live#Part]]';
      final ranges = deadLinkRanges(
        line(text),
        const DeadLinks(wiki: {'Gone', 'shown'}),
      );
      expect(
        [for (final r in ranges) text.substring(r.start, r.end)],
        ['[[Gone#Part|shown]]'],
      );
    });

    test('a link title is not part of the destination', () {
      const text = '[x](missing.md "the title") [y](<missing two.md>)';
      final ranges = deadLinkRanges(
        line(text),
        const DeadLinks(href: {'missing.md', 'missing two.md'}),
      );
      expect(ranges, hasLength(2));
    });

    test('a reference link is judged by the target the parse found', () {
      // The styler (not the plain tokenizer) reads `[x][ref]` as a link: a
      // run of link tokens that spells no `](href)`.
      const text = '[x][ref] and [y][ok]';
      const styled = StyledLine(text, [
        Token(TokenKind.link, 0, 8),
        Token(TokenKind.link, 13, 20),
      ]);
      final ranges = deadLinkRanges(
        styled,
        const DeadLinks(href: {'missing.md'}),
        hrefOf: (start) => start == 0 ? 'missing.md' : 'ok.md',
      );
      expect(ranges, hasLength(1));
      expect(ranges.single.start, 0);
    });

    test('nothing dead, nothing to range', () {
      expect(deadLinkRanges(line('[[Gone]]'), DeadLinks.none), isEmpty);
      expect(
        deadLinkRanges(line('no links'), const DeadLinks(wiki: {'a'})),
        isEmpty,
      );
    });
  });

  group('inlineHrefOf', () {
    test('reads the destination, not a title', () {
      expect(inlineHrefOf('[t](a.md)'), 'a.md');
      expect(inlineHrefOf('[t](a.md "the title")'), 'a.md');
      expect(inlineHrefOf('[t](<a b.md>)'), '<a b.md>');
      expect(inlineHrefOf('[t][label]'), isNull);
    });

    test('a bracket in the text does not end it', () {
      expect(inlineHrefOf('[![a](i.png)](missing.md)'), 'missing.md');
      expect(inlineHrefOf('[a [b] c](x.md)'), 'x.md');
      expect(inlineHrefOf(r'[a \] b](x.md)'), 'x.md');
      expect(inlineHrefOf('[![a](i.png)][ref]'), isNull);
    });
  });

  group('DeadLinkWatcher', () {
    late FakeLinkSource source;
    late List<ParsedLink> links;
    late int reads;
    late DeadLinkWatcher watcher;
    var delay = Duration.zero;
    var notified = 0;

    setUp(() {
      source = FakeLinkSource(notes: ['Live.md']);
      links = parseLinks('[[Live]] [[Gone]]');
      delay = Duration.zero;
      notified = 0;
      reads = 0;
      watcher = DeadLinkWatcher(
        source: () => source,
        links: () async {
          reads++;
          return links;
        },
        notePath: () => 'n.md',
        delay: () => delay,
      )..addListener(() => notified++);
      addTearDown(watcher.dispose);
    });

    test('nothing is dead before the first resolution', () {
      expect(watcher.value, DeadLinks.none);
    });

    test("refresh resolves the note's links and tells the listeners", () async {
      watcher.refresh();
      await pumpEventQueue();

      expect(watcher.value.wiki, {'Gone'});
      expect(notified, 1);
      expect(source.deadChecks, 1);
    });

    test('the same answer again does not wake the drawing', () async {
      watcher.refresh();
      await pumpEventQueue();
      watcher.refresh();
      await pumpEventQueue();

      expect(source.deadChecks, 2);
      expect(notified, 1, reason: 'nothing changed, nothing is drawn again');
    });

    test('an edit waits out the pause and resolves once', () async {
      delay = const Duration(milliseconds: 30);
      watcher
        ..edited()
        ..edited()
        ..edited();
      await pumpEventQueue();
      expect(source.deadChecks, 0, reason: 'inside the pause');

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(source.deadChecks, 1, reason: 'three edits, one resolution');
      expect(watcher.value.wiki, {'Gone'});
    });

    test('the library announcing a change resolves the links again', () async {
      watcher.refresh();
      await pumpEventQueue();
      expect(watcher.value.wiki, {'Gone'});

      source.notes.add('Gone.md');
      source.announceChange();
      await pumpEventQueue();
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();

      expect(watcher.value, DeadLinks.none, reason: 'the note exists now');
    });

    // A library busy elsewhere moves its index often; the open note's text
    // did not change, so the links already read are resolved again, and the
    // note is read anew only after an edit.
    test('an index move resolves the links read; an edit reads them', () async {
      watcher.refresh();
      await pumpEventQueue();
      expect(reads, 1);

      source.notes.add('Gone.md');
      source.announceChange();
      await pumpEventQueue();
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();
      expect(watcher.value, DeadLinks.none);
      expect(source.deadChecks, 2);
      expect(reads, 1, reason: 'the index moved, the text did not');

      links = parseLinks('[[Live]] [[Other]]');
      watcher.edited();
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();
      expect(reads, 2, reason: 'an edit reads the links again');
      expect(watcher.value.wiki, {'Other'});
    });

    test('an older resolution never lands over a newer one', () async {
      final gate = Completer<void>();
      var first = true;
      final slow = DeadLinkWatcher(
        source: () => source,
        links: () async {
          if (first) {
            first = false;
            await gate.future;
            return parseLinks('[[Old gone]]');
          }
          return parseLinks('[[Gone]]');
        },
        notePath: () => null,
        delay: () => Duration.zero,
      );
      addTearDown(slow.dispose);

      slow
        ..refresh()
        ..refresh();
      await pumpEventQueue();
      expect(slow.value.wiki, {'Gone'});

      gate.complete();
      await pumpEventQueue();
      expect(slow.value.wiki, {'Gone'}, reason: 'the late answer is dropped');
    });

    test("clear forgets the previous note's links", () async {
      watcher.refresh();
      await pumpEventQueue();
      watcher.clear();

      expect(watcher.value, DeadLinks.none);
      expect(notified, 2);
    });

    test('no library, or no links to give, leaves nothing dead', () async {
      final none = DeadLinkWatcher(
        source: () => null,
        links: () async => links,
        notePath: () => null,
        delay: () => Duration.zero,
      );
      addTearDown(none.dispose);
      none.refresh();
      await pumpEventQueue();
      expect(none.value, DeadLinks.none);
    });

    test(
      'a note read for its links is read the way the index reads it',
      () async {
        const text =
            '[[Gone]] `[[In code]]`\n\n```\n[[In fence]]\n```\n[x](y.md)';
        final read = await linksOfText(text);
        expect(read.whereType<WikiLink>().map((l) => l.ref.target), ['Gone']);
        expect(read.whereType<MarkdownLink>().map((l) => l.href), ['y.md']);

        final long = '${'filler line\n' * 8000}[[Far gone]]';
        expect(long.length, greaterThan(deadLinkInlineLimit));
        expect(
          (await linksOfText(long)).whereType<WikiLink>().single.ref.target,
          'Far gone',
          reason: 'a long note is read on an isolate, and answers the same',
        );
      },
    );
  });
}
