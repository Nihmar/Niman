import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:niman/src/core/changelog.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/strings.dart';

/// The full changelog, every shipped version from newest to oldest
/// (issue #80).
///
/// Reached from Settings → About. The update dialog on launch shows the
/// same blocks, filtered to what the user has not seen yet.
final class ChangelogScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.changelogTitle)),
      body: Consumer(
        builder: (context, ref, _) {
          final entries = ref.watch(changelogProvider).value;
          if (entries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return Center(child: Text(AppStrings.changelogEmpty));
          }
          // The list's own 16-pixel padding each side is not part of the
          // width a bullet wraps at.
          return LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: changelogEntryBlock(
                      context,
                      entry,
                      width: constraints.maxWidth - 32,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The launch dialog: what changed since the version the user last saw
/// (issue #80).
///
/// One version reads "What's new in X"; several (the user skipped
/// releases) fall back to the plain title, each version as its own block.
Future<void> showChangelogUpdateDialog(
  BuildContext context,
  List<ChangelogVersion> versions,
) {
  final title = versions.length == 1
      ? AppStrings.changelogWhatsNew(versions.single.version)
      : AppStrings.changelogTitle;
  // `AlertDialog` measures its content with an intrinsic pass, and a
  // `LayoutBuilder` cannot answer one: the bullets are laid out at a width
  // taken from the window, less the dialog's own inset (40 a side) and
  // content padding (24 a side). A little over and the constraint clamps it.
  final width = MediaQuery.sizeOf(context).width - 128;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('changelog-update-dialog'),
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in versions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: changelogEntryBlock(context, entry, width: width),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('changelog-update-ok'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionOk),
        ),
      ],
    ),
  );
}

/// One version's block, shared by the screen and the launch dialog:
/// the version (and its date, when it has one) as a header, then each
/// group — its heading when it has one, then its bullets.
///
/// The bullets are drawn as the Markdown they are written in, through the
/// read view's own block painter (`MarkdownExportView`), so `**bold**` and
/// `` `code` `` read as they would in a note. [width] is how wide to lay
/// them out: an `AlertDialog` measures its content intrinsically and cannot
/// take a `LayoutBuilder`, so the width is handed in rather than read here.
Widget changelogEntryBlock(
  BuildContext context,
  ChangelogVersion entry, {
  required double width,
}) => _ChangelogEntry(entry: entry, width: width);

/// One version, drawn with its bullets as Markdown.
final class _ChangelogEntry extends StatefulWidget {
  const new({required this.entry, required this.width});

  /// The version to draw.
  final ChangelogVersion entry;

  /// How wide its bullets lay out.
  final double width;

  @override
  State<_ChangelogEntry> createState() => _ChangelogEntryState();
}

final class _ChangelogEntryState extends State<_ChangelogEntry> {
  /// The block parser, shared by every section of this version.
  final BlockParser _parser = BlockParser();

  /// The version's formulas, typeset once.
  final MathCache _mathCache = MathCache();

  @override
  void dispose() {
    _mathCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final date = entry.date;
    final markdown = markdownThemeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date == null
              ? entry.version
              : '${entry.version} · ${date.toIso8601String().substring(0, 10)}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        for (final section in entry.sections) ...[
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                section.title!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          if (section.items.isNotEmpty)
            MarkdownExportView(
              buffer: SourceBuffer.fromText(_bulletList(section.items)),
              parser: _parser,
              theme: markdown,
              mathCache: _mathCache,
              width: widget.width,
              padding: const EdgeInsets.only(left: 8),
            ),
        ],
      ],
    );
  }
}

/// [items] as the Markdown list the read view draws: one `- ` line each.
String _bulletList(List<String> items) =>
    '${items.map((item) => '- $item').join('\n')}\n';
