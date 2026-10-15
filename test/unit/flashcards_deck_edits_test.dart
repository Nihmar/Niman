// #943: a card edit finds its card again in the note as it is now; it never
// splices at the offsets of a card read from an older text.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_edits.dart';

final class _Host implements NoteKindHost {
  new(this.text);

  @override
  String text;

  @override
  void applyEdit(String newText) => text = newText;

  @override
  String? get libraryRoot => null;

  @override
  String get notePath => 'Deck.md';

  @override
  String get attachmentsFolder => '';

  @override
  LinkType get linkType => LinkType.wikilink;

  @override
  Future<String?> resolveEmbed(String target) async => null;

  @override
  void openLink(BuildContext context, String href) {}

  @override
  void openWikiLink(BuildContext context, String inner) {}

  @override
  VoidCallback? get showMarkdown => null;
}

const String _table =
    '| Verb | Past |\n'
    '|---|---|\n'
    '| begin | began |\n'
    '| choose | chose |\n'
    '| tread | trod |\n';

DeckCardEdits _edits(_Host host) => DeckCardEdits(host);

void main() {
  group('a card read from an older text', () {
    test('is rewritten where the note has it now', () async {
      final host = _Host(_table);
      final stale = Deck.read(host.text).cards[1];
      // A row was added above the card while the sheet was open.
      host.text = _table.replaceFirst(
        '| begin | began |\n',
        '| be | was |\n| begin | began |\n',
      );
      await _edits(host).rewrite(stale, question: 'choose', answer: 'chosen');
      expect(
        host.text,
        '| Verb | Past |\n'
        '|---|---|\n'
        '| be | was |\n'
        '| begin | began |\n'
        '| choose | chosen |\n'
        '| tread | trod |\n',
      );
    });

    test('is deleted where the note has it now', () async {
      final host = _Host(_table);
      final stale = Deck.read(host.text).cards[2];
      host.text = _table.replaceFirst(
        '| begin | began |\n',
        '| be | was |\n| begin | began |\n',
      );
      await _edits(host).delete(stale);
      expect(
        host.text,
        _table
            .replaceFirst('| tread | trod |\n', '')
            .replaceFirst(
              '| begin | began |\n',
              '| be | was |\n| begin | began |\n',
            ),
      );
    });

    test('is not edited once the note no longer has it', () async {
      final host = _Host(_table);
      final stale = Deck.read(host.text).cards[1];
      final moved = _table.replaceFirst('| choose | chose |\n', '');
      host.text = moved;
      final edits = _edits(host);
      await edits.rewrite(stale, question: 'choose', answer: 'chosen');
      await edits.delete(stale);
      expect(host.text, moved);
    });

    test('a cloze sentence is rewritten where the note has it now', () async {
      const note = 'Rome was ==built== in a day.\n';
      final host = _Host(note);
      final stale = Deck.read(host.text).cards.single;
      host.text = 'A line above.\n\n$note';
      await _edits(host).rewriteSentence(stale, 'Rome was ==not built== here.');
      expect(host.text, 'A line above.\n\nRome was ==not built== here.\n');
    });

    test('a row added goes to the table as it is now', () async {
      final host = _Host(
        _table.replaceFirst(
          '| begin | began |\n',
          '| be | was |\n| begin | began |\n',
        ),
      );
      await _edits(host).add(question: 'sing', answer: 'sang');
      expect(host.text, endsWith('| tread | trod |\n| sing | sang |\n'));
      expect(host.text, contains('| be | was |\n'));
    });
  });

  test('two deletes before a long deck is re-read both land', () async {
    // From Deck.isolateFrom the read is a hop to an isolate: both deletes
    // start from the same text, as two clicks before the re-read lands.
    final pad = 'filler words\n\n' * (Deck.isolateFrom ~/ 14 + 1);
    final text = '$pad$_table';
    final host = _Host(text);
    final cards = Deck.read(text).cards;
    expect(text.length, greaterThanOrEqualTo(Deck.isolateFrom));
    final edits = _edits(host);
    await Future.wait([edits.delete(cards[0]), edits.delete(cards[1])]);
    expect(host.text, '$pad| Verb | Past |\n|---|---|\n| tread | trod |\n');
  });
}
