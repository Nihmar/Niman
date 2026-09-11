import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/ui/strings.dart';

/// The Tags screen (T-M3-06): the tag list with counts, and per tag the
/// notes carrying it (path order) that open on tap.
///
/// Two levels, both inside the tab body: a tag-list view and (after a tap)
/// the tag's notes with a back affordance. Both sources — frontmatter
/// `tags:` and inline `#tags` — land in `note_tags` at index time, so the
/// list reflects them together; tags are normalized (lowercase, no `#`).
final class TagsScreen extends StatefulWidget {
  /// Creates the tags screen.
  const new({
    required this.controller,
    required this.onOpenNote,
    required this.onBack,
    this.sourceOverride,
    super.key,
  });

  /// The open library session (for the tag source).
  final LibrarySession controller;

  /// Called with the note's library-relative path when a note is tapped.
  final void Function(String path) onOpenNote;

  /// Called when the user leaves the tags view (back to the search view).
  final VoidCallback onBack;

  /// Optional source override (widget tests inject a fake); when null the
  /// screen resolves it from [controller].
  final TagSource? sourceOverride;

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

final class _TagsScreenState extends State<TagsScreen> {
  TagSource? _source;
  List<TagCount>? _counts;
  String? _selectedTag;
  List<Note>? _notes;

  @override
  void initState() {
    super.initState();
    const AppLogger(name: 'tags.ui').debug('mount');
    unawaited(_load());
  }

  Future<void> _load() async {
    final started = DateTime.now();
    final source = widget.sourceOverride ?? await widget.controller.tagSource;
    if (source == null) return;
    final counts = await source.tagCounts();
    if (!mounted) return;
    const AppLogger(name: 'tags.ui').debug(
      'tag counts: ${counts.length} tags in '
      '${DateTime.now().difference(started).inMilliseconds}ms',
    );
    setState(() {
      _source = source;
      _counts = counts;
    });
    logNextFrame('tags.ui', 'tag list first frame');
  }

  Future<void> _openTag(String tag) async {
    final source = _source;
    if (source == null) return;
    setState(() => _selectedTag = tag);
    final notes = await source.notesWithTag(tag);
    if (!mounted || _selectedTag != tag) return;
    setState(() => _notes = notes);
  }

  void _backToTags() {
    setState(() {
      _selectedTag = null;
      _notes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tag = _selectedTag;
    return tag == null ? _tagList() : _noteList(tag);
  }

  Widget _tagList() {
    final counts = _counts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              IconButton(
                key: const Key('tags-back'),
                tooltip: AppStrings.tagsBackTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  AppStrings.tagsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _tagCounts(counts)),
      ],
    );
  }

  Widget _tagCounts(List<TagCount>? counts) {
    if (counts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (counts.isEmpty) {
      return Center(
        child: Text(
          AppStrings.tagsEmpty,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      key: const Key('tags-list'),
      itemCount: counts.length,
      itemBuilder: (context, index) {
        final tag = counts[index];
        return ListTile(
          key: Key('tag-$index'),
          leading: const Icon(Icons.sell_outlined),
          title: Text('#${tag.name}'),
          trailing: Text(
            '${tag.count}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => unawaited(_openTag(tag.name)),
        );
      },
    );
  }

  Widget _noteList(String tag) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              IconButton(
                key: const Key('tags-back'),
                tooltip: AppStrings.tagsBackTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToTags,
              ),
              Expanded(
                child: Text(
                  '#$tag',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _notesOf(tag)),
      ],
    );
  }

  Widget _notesOf(String tag) {
    final notes = _notes;
    if (notes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notes.isEmpty) {
      return Center(
        child: Text(
          AppStrings.tagsNotesEmpty,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    // The last row says so when the tag has more notes than the list
    // carries: a count of 12 000 next to a list of 500 is otherwise a
    // list that looks wrong (T-M6-01).
    final capped = notes.length >= tagNotesLimit;
    return ListView.builder(
      key: const Key('tag-notes'),
      itemCount: notes.length + (capped ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= notes.length) {
          return ListTile(
            key: const Key('tag-notes-capped'),
            leading: const Icon(Icons.more_horiz),
            title: Text(
              AppStrings.tagsNotesCapped(tagNotesLimit),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final note = notes[index];
        return ListTile(
          key: Key('tag-note-${note.path}'),
          leading: const Icon(Icons.description_outlined),
          title: Text(note.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            note.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => widget.onOpenNote(note.path),
        );
      },
    );
  }
}
