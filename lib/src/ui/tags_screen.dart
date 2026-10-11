import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/ui/search_request.dart';
import 'package:niman/src/ui/strings.dart';

/// The Tags screen (T-M3-06): the tag list with counts, and per tag the
/// notes carrying it (path order) that open on tap.
///
/// Two shapes. The phone's is a drill-down: the tag list, then (after a
/// tap) the tag's notes with a back affordance. The wide sidebar's is a
/// collapsible tree (#712): a tag's nested tags and its own notes open
/// under it, no page to leave. Both sources — frontmatter `tags:` and
/// inline `#tags` — land in `note_tags` at index time, so the list
/// reflects them together; tags are normalized (lowercase, no `#`).
final class TagsScreen extends StatefulWidget {
  /// Creates the tags screen.
  const new({
    required this.controller,
    required this.onOpenNote,
    required this.onBack,
    this.sourceOverride,
    this.requests,
    this.tree = false,
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

  /// What another part of the app asks Search to show (#535): a tag's
  /// notes open here.
  final ValueListenable<SearchRequest?>? requests;

  /// Whether the tags are drawn as a collapsible tree (#712), the wide
  /// sidebar's shape. False keeps the two-level drill-down a phone uses.
  final bool tree;

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

final class _TagsScreenState extends State<TagsScreen> {
  TagSource? _source;
  List<TagCount>? _counts;
  String? _selectedTag;
  List<Note>? _notes;

  /// The tags open in the tree (#712), by full tag.
  final Set<String> _open = <String>{};

  /// The notes a tag opened in the tree carries, by tag; absent while
  /// they are still being read.
  final Map<String, List<Note>> _treeNotes = <String, List<Note>>{};

  @override
  void initState() {
    super.initState();
    const AppLogger(name: 'tags.ui').debug('mount');
    widget.requests?.addListener(_requested);
    unawaited(_load());
  }

  @override
  void dispose() {
    widget.requests?.removeListener(_requested);
    super.dispose();
  }

  /// Opens a requested tag, once the counts are in.
  void _requested() {
    final tag = widget.requests?.value?.tag;
    if (tag == null || _source == null) return;
    unawaited(widget.tree ? _openInTree(tag) : _openTag(tag));
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
    _requested();
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

  /// Opens or closes [tag] in the tree; opening reads its notes once.
  Future<void> _toggleTag(String tag) async {
    if (_open.contains(tag)) {
      setState(() => _open.remove(tag));
      return;
    }
    setState(() => _open.add(tag));
    if (_treeNotes.containsKey(tag)) return;
    final source = _source;
    if (source == null) return;
    final notes = await source.notesWithTag(tag);
    if (!mounted || !_open.contains(tag)) return;
    setState(() => _treeNotes[tag] = notes);
  }

  /// Opens [tag] in the tree, its ancestors with it (#535 asked for it).
  Future<void> _openInTree(String tag) async {
    final parts = tag.split('/');
    for (var i = 1; i <= parts.length; i++) {
      _open.add(parts.take(i).join('/'));
    }
    if (_treeNotes.containsKey(tag)) {
      setState(() {});
      return;
    }
    final source = _source;
    if (source == null) return;
    final notes = await source.notesWithTag(tag);
    if (!mounted) return;
    setState(() => _treeNotes[tag] = notes);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tree) return _treeView();
    final tag = _selectedTag;
    return tag == null ? _tagList() : _noteList(tag);
  }

  /// The view's header: the way back — to the search view, or to the tag
  /// list — and what the view is.
  Widget _header(String title, {required VoidCallback onBack}) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
    child: Row(
      children: [
        IconButton(
          key: const Key('tags-back'),
          tooltip: AppStrings.tagsBackTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  /// The phone's first level: every tag, most used first.
  Widget _tagList() => Column(
    children: [
      _header(AppStrings.tagsTitle, onBack: widget.onBack),
      Expanded(child: _tagCounts(_counts)),
    ],
  );

  /// The wide sidebar's tree (#712): tags nested by `/`, each opening its
  /// child tags and its own notes under it.
  Widget _treeView() => Column(
    children: [
      _header(AppStrings.tagsTitle, onBack: widget.onBack),
      Expanded(child: _tagTree(_counts)),
    ],
  );

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

  Widget _tagTree(List<TagCount>? counts) {
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
    final rows = _treeRows(counts);
    return ListView.builder(
      key: const Key('tags-tree'),
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _TagNodeRow(
          :final tag,
          :final count,
          :final depth,
          :final open,
          :final hasChildren,
        ) =>
          _tagNodeTile(tag, count, depth, open, hasChildren),
        _TagLoadingRow(:final depth) => _tagLoadingTile(depth),
        _TagNoteRow(:final note, :final depth) => _tagNoteTile(note, depth),
      },
    );
  }

  /// The tree's rows in display order: each tag, then — when it is open —
  /// its child tags and, deepest, its own notes.
  ///
  /// The count on a tag is its own (`#a` does not count `#a/b`), so the
  /// number matches the notes the tap lists; a tag that is only a parent
  /// shows none.
  List<_TagRow> _treeRows(List<TagCount> counts) {
    final exact = {for (final count in counts) count.name: count.count};
    final nodes = <String, _TagNode>{};
    for (final count in counts) {
      final parts = count.name.split('/');
      for (var i = 1; i <= parts.length; i++) {
        nodes.putIfAbsent(parts.take(i).join('/'), () {
          final path = parts.take(i).join('/');
          return _TagNode(path);
        });
      }
    }
    for (final node in nodes.values) {
      final at = node.tag.lastIndexOf('/');
      if (at >= 0) nodes[node.tag.substring(0, at)]?.children.add(node);
    }
    int compare(_TagNode a, _TagNode b) {
      final ca = exact[a.tag] ?? 0;
      final cb = exact[b.tag] ?? 0;
      return cb != ca ? cb.compareTo(ca) : a.tag.compareTo(b.tag);
    }

    final rows = <_TagRow>[];
    void walk(_TagNode node, int depth) {
      final open = _open.contains(node.tag);
      rows.add(
        _TagNodeRow(
          tag: node.tag,
          count: exact[node.tag] ?? 0,
          depth: depth,
          open: open,
          hasChildren: node.children.isNotEmpty,
        ),
      );
      if (!open) return;
      final children = [...node.children]..sort(compare);
      for (final child in children) {
        walk(child, depth + 1);
      }
      final notes = _treeNotes[node.tag];
      if (notes == null) {
        rows.add(_TagLoadingRow(depth: depth + 1));
      } else {
        for (final note in notes) {
          rows.add(_TagNoteRow(note: note, depth: depth + 1));
        }
      }
    }

    final roots = [
      for (final node in nodes.values)
        if (!node.tag.contains('/')) node,
    ]..sort(compare);
    for (final root in roots) {
      walk(root, 0);
    }
    return rows;
  }

  /// One tag line of the tree: chevron, name, own count.
  Widget _tagNodeTile(
    String tag,
    int count,
    int depth,
    bool open,
    bool hasChildren,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      key: Key('tag-node-$tag'),
      dense: true,
      contentPadding: EdgeInsetsDirectional.only(
        start: 4 + depth * 14,
        end: 12,
      ),
      leading: Icon(
        hasChildren
            ? (open ? Icons.expand_more : Icons.chevron_right)
            : Icons.sell_outlined,
        size: 18,
      ),
      title: Text(
        tag.substring(tag.lastIndexOf('/') + 1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: count > 0
          ? Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      onTap: () => unawaited(_toggleTag(tag)),
    );
  }

  /// The notes of an open tag being read.
  Widget _tagLoadingTile(int depth) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: 4 + depth * 14 + 16,
      top: 10,
      bottom: 10,
    ),
    child: const Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  /// One note under the tag that carries it.
  Widget _tagNoteTile(Note note, int depth) => ListTile(
    key: Key('tag-note-${note.path}'),
    dense: true,
    contentPadding: EdgeInsetsDirectional.only(start: 4 + depth * 14, end: 12),
    leading: const Icon(Icons.description_outlined, size: 18),
    title: Text(note.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(note.path, maxLines: 1, overflow: TextOverflow.ellipsis),
    onTap: () => widget.onOpenNote(note.path),
  );

  Widget _noteList(String tag) => Column(
    children: [
      _header('#$tag', onBack: _backToTags),
      Expanded(child: _notesOf(tag)),
    ],
  );

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

/// One tag of the tree, with the tags nested under it.
final class _TagNode {
  /// Creates a node for [tag].
  new(this.tag);

  /// The full tag (`a/b`).
  final String tag;

  /// The tags directly under it.
  final List<_TagNode> children = <_TagNode>[];
}

/// One row of the tree, in display order.
sealed class _TagRow {
  const new();
}

/// A tag line.
final class _TagNodeRow extends _TagRow {
  /// Creates the row for [tag] at [depth], [open] or closed.
  const new({
    required this.tag,
    required this.count,
    required this.depth,
    required this.open,
    required this.hasChildren,
  });

  final String tag;
  final int count;
  final int depth;
  final bool open;

  /// Whether tags nest under it: it gets the chevron and the tap that
  /// opens them.
  final bool hasChildren;
}

/// The placeholder while an open tag's notes are read.
final class _TagLoadingRow extends _TagRow {
  /// Creates the row at [depth].
  const new({required this.depth});

  final int depth;
}

/// A note under the tag that carries it.
final class _TagNoteRow extends _TagRow {
  /// Creates the row for [note] at [depth].
  const new({required this.note, required this.depth});

  final Note note;
  final int depth;
}
