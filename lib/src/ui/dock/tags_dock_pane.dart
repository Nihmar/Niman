import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';

/// The tags of [text]: its frontmatter's, then its inline `#tags`, each
/// once and normalized — what the index keeps for the note.
List<String> noteTagsOf(String text) {
  final front = parseFrontmatter(text)?.tags ?? const <String>[];
  return {...front.map(normalizeTag), ...inlineTags(text)}.toList();
}

/// The dock's tags (#175): the note's own, each opening onto the other
/// notes that carry it. They follow the note as it is edited.
final class TagsDockPane extends StatefulWidget {
  /// The tags of [note], looked up in [tags].
  const new({
    required this.note,
    required this.tags,
    required this.onOpenNote,
    super.key,
  });

  /// The note shown beside; null when none is open.
  final NoteViewHandle? note;

  /// Where a tag's other notes are found.
  final Future<TagSource?> tags;

  /// Opens one of those notes.
  final ValueChanged<String> onOpenNote;

  @override
  State<TagsDockPane> createState() => _TagsDockPaneState();
}

final class _TagsDockPaneState extends State<TagsDockPane> {
  List<String>? _tags;
  String? _open;
  List<String>? _notes;
  int _revision = 0;

  /// Past this, reading the tags tokenizes the note on an isolate.
  static const int _syncLimit = 64 * 1024;

  @override
  void initState() {
    super.initState();
    _listen(widget.note);
    unawaited(_read());
  }

  @override
  void didUpdateWidget(TagsDockPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note != widget.note) {
      oldWidget.note?.outline.removeListener(_onEdit);
      _listen(widget.note);
      _open = null;
      _notes = null;
      unawaited(_read());
    }
  }

  @override
  void dispose() {
    widget.note?.outline.removeListener(_onEdit);
    super.dispose();
  }

  /// The outline moves after every pause in the typing: the same moment
  /// the tags may have.
  void _listen(NoteViewHandle? note) => note?.outline.addListener(_onEdit);

  void _onEdit() => unawaited(_read());

  Future<void> _read() async {
    final note = widget.note;
    if (note == null) return;
    final revision = ++_revision;
    final text = note.currentText;
    final tags = text.length > _syncLimit
        ? await Isolate.run(() => noteTagsOf(text))
        : noteTagsOf(text);
    if (!mounted || revision != _revision) return;
    setState(() => _tags = tags);
  }

  Future<void> _toggle(String tag) async {
    if (_open == tag) {
      setState(() {
        _open = null;
        _notes = null;
      });
      return;
    }
    setState(() {
      _open = tag;
      _notes = null;
    });
    final source = await widget.tags;
    final notes = await source?.notesWithTag(tag) ?? const [];
    if (!mounted || _open != tag) return;
    setState(() => _notes = [for (final note in notes) note.path]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = _tags;
    if (tags == null) return const SizedBox.shrink();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(AppStrings.tagsEmpty, style: muted),
      );
    }
    final notes = _notes;
    return ListView(
      key: const Key('dock-tags'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final tag in tags) ...[
          ListTile(
            key: Key('dock-tag-$tag'),
            dense: true,
            leading: const Icon(Icons.tag, size: 18),
            title: Text(tag),
            trailing: Icon(
              _open == tag ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            onTap: () => unawaited(_toggle(tag)),
          ),
          if (_open == tag)
            if (notes == null)
              const LinearProgressIndicator(minHeight: 2)
            else if (notes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                child: Text(AppStrings.tagsNotesEmpty, style: muted),
              )
            else
              for (final path in notes)
                ListTile(
                  key: Key('dock-tag-note-$path'),
                  dense: true,
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 56,
                    end: 16,
                  ),
                  title: Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => widget.onOpenNote(path),
                ),
        ],
      ],
    );
  }
}
