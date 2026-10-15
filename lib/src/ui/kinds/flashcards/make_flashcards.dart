import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/deck_catalog.dart';
import 'package:niman/src/flashcards/deck_table.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/flashcards/make_deck.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_columns_dialog.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/study/study_offer.dart';

/// **Make flashcards** (#533, mockup D6): turns the plain note [note] into
/// a deck without touching its text. The cards it already holds — table
/// rows, `::` lines, highlights — are counted; the dialog asks for the
/// question and answer columns when a table has more than two and for the
/// `deck:`, the decks [session]'s library has offered; it shows the
/// frontmatter it will write, and writes it as one undoable edit.
Future<void> makeFlashcards(
  BuildContext context, {
  required NoteViewHandle note,
  required LibrarySession session,
}) async {
  final text = note.currentText;
  final deck = await Deck.readOffUi(text);
  if (!context.mounted) return;
  if (deck.cards.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppStrings.makeFlashcardsNone)));
    return;
  }
  final places = await _deckPlaces(session);
  if (!context.mounted) return;
  final made = await showDialog<_Made>(
    context: context,
    builder: (context) =>
        _MakeDialog(head: _head(text), deck: deck, places: places),
  );
  if (made == null || !context.mounted) return;
  // The text may have moved while the dialog was open.
  note.applyKindEdit(
    makeDeckText(
      note.currentText,
      deck: made.deck,
      front: made.front,
      back: made.back,
    ),
  );
  await offerStudy(context, session);
}

typedef _Made = ({String deck, String? front, String? back});

/// The note's frontmatter with its line end, or nothing: all the preview
/// needs to be written on, whatever the length of the body.
String _head(String text) {
  final head = frontmatterOf(text);
  return head.isEmpty ? '' : '$head\n';
}

/// The `deck:` values the library's decks hold, in order: the places a new
/// deck is offered. A `deck:` of a note that is no deck means something
/// else, and is left out.
Future<List<String>> _deckPlaces(LibrarySession session) async {
  final fields = await session.fieldSource;
  if (fields == null) return const [];
  final decks = await findDeckPaths(fields);
  final values = {
    for (final (:note, :value) in await fields.fieldValues('deck'))
      if (value.trim().isNotEmpty && decks.contains(note.path)) value.trim(),
  };
  return values.toList()..sort();
}

final class _MakeDialog extends StatefulWidget {
  const new({required this.head, required this.deck, required this.places});

  final String head;
  final Deck deck;
  final List<String> places;

  @override
  State<_MakeDialog> createState() => _MakeDialogState();
}

final class _MakeDialogState extends State<_MakeDialog> {
  /// The first table whose question and answer columns are a choice.
  late final DeckTable? _wide = widget.deck.tables
      .where((table) => table.columns > 2)
      .firstOrNull;

  late DeckColumns? _columns = switch (_wide) {
    final table? => (question: table.question, answer: table.answer),
    null => null,
  };

  String _place = '';

  _Made get _made {
    final table = _wide;
    final columns = _columns;
    return (
      deck: _place,
      front: table == null || columns == null
          ? null
          : table.headers[columns.question],
      back: table == null || columns == null
          ? null
          : table.headers[columns.answer],
    );
  }

  bool get _valid => switch ((_wide, _columns)) {
    (final table?, final columns?) => deckColumnsValid(table, columns),
    _ => true,
  };

  String get _found {
    int count(CardKind kind) =>
        widget.deck.cards.where((card) => card.kind == kind).length;
    final rows = count(CardKind.tableRow);
    final lines = count(CardKind.line);
    final clozes = count(CardKind.cloze);
    return [
      if (rows > 0) AppStrings.flashcardsKindRows(rows),
      if (lines > 0) AppStrings.flashcardsKindLines(lines),
      if (clozes > 0) AppStrings.flashcardsKindClozes(clozes),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final made = _made;
    final preview = frontmatterOf(
      makeDeckText(
        widget.head,
        deck: made.deck,
        front: made.front,
        back: made.back,
      ),
    );
    return AlertDialog(
      title: Text(AppStrings.makeFlashcardsTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _found,
                key: const Key('make-flashcards-found'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_wide case final table?) ...[
                DeckColumnFields(
                  table: table,
                  columns: _columns!,
                  onChanged: (columns) => setState(() => _columns = columns),
                ),
                const SizedBox(height: 12),
              ],
              Autocomplete<String>(
                optionsBuilder: (value) {
                  final typed = value.text.trim().toLowerCase();
                  return widget.places.where(
                    (place) => place.toLowerCase().contains(typed),
                  );
                },
                onSelected: (place) => setState(() => _place = place),
                fieldViewBuilder: (context, controller, focus, onSubmitted) =>
                    TextField(
                      key: const Key('make-flashcards-deck'),
                      controller: controller,
                      focusNode: focus,
                      decoration: InputDecoration(
                        labelText: AppStrings.makeFlashcardsDeck,
                        helperText: AppStrings.makeFlashcardsDeckHint,
                      ),
                      onChanged: (value) => setState(() => _place = value),
                      onSubmitted: (_) => onSubmitted(),
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.makeFlashcardsWrites,
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  preview,
                  key: const Key('make-flashcards-preview'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('make-flashcards-confirm'),
          onPressed: _valid ? () => Navigator.pop(context, _made) : null,
          child: Text(
            AppStrings.makeFlashcardsAction(widget.deck.cards.length),
          ),
        ),
      ],
    );
  }
}
