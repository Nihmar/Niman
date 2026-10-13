import 'package:flutter/material.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/ui/links_to_note_controller.dart';
import 'package:niman/src/ui/links_to_note_list.dart';
import 'package:niman/src/ui/strings.dart';

/// The note view's own "Links to this note" (#842): a header under the note
/// that opens onto the notes that link to it, collapsed to a count until it
/// is asked for.
///
/// The header is always there while a library is open, so it never appears
/// under a thumb that was already on the row below; with no one linking in it
/// opens onto the words that say so. The dock's pane and the phone's sheet
/// list the same notes.
final class LinksToNoteSection extends StatefulWidget {
  /// The notes of [source] that link to the note at library-relative [path];
  /// [onOpenNote] opens one of them.
  const new({
    required this.source,
    required this.path,
    required this.onOpenNote,
    super.key,
  });

  /// The library the notes are looked up in, or null while none is open.
  final MentionSource? source;

  /// The note's library-relative path, or null for a note outside a library.
  final String? path;

  /// Opens the note at a library-relative path.
  final ValueChanged<String> onOpenNote;

  /// How tall the opened list is at most: a few rows, scrolled for the rest.
  static const double maxListHeight = 220;

  @override
  State<LinksToNoteSection> createState() => _LinksToNoteSectionState();
}

final class _LinksToNoteSectionState extends State<LinksToNoteSection> {
  final LinksToNoteController _controller = LinksToNoteController();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller.target(widget.source, widget.path);
  }

  @override
  void didUpdateWidget(LinksToNoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.target(widget.source, widget.path);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.source == null || widget.path == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const Key('links-to-note-section'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final known = _controller.referrers != null;
              final count =
                  '${_controller.count}'
                  '${_controller.truncated ? '+' : ''}';
              return InkWell(
                key: const Key('links-to-note-header'),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _open ? Icons.expand_more : Icons.chevron_right,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.linksToNoteTitle,
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      if (known)
                        Text(
                          count,
                          key: const Key('links-to-note-count'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_open)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: LinksToNoteSection.maxListHeight,
              ),
              child: LinksToNoteList(
                controller: _controller,
                onOpenNote: widget.onOpenNote,
                shrinkWrap: true,
              ),
            ),
        ],
      ),
    );
  }
}
