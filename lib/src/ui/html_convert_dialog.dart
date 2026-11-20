/// The one question a web page's conversion into a note asks (#1293): which
/// folder it goes in.
///
/// It names the page by its file, and says nothing of what is in it: the
/// page is not read here, since a reading is disk work and the UI isolate
/// does none. The conversion's own isolate reads it. A book's dialog asks
/// how to cut it too (#1294); this is where that choice will go.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/import/html/html_conversion.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What the dialog answers: the folder the pages go in, library-relative
/// ('' for the top).
typedef HtmlConvertChoice = ({String parent});

/// Asks where to convert the pages at [sources] to; null when the dialog is
/// dismissed. [name] is what the page is called when its file is not (a
/// share's copy in the cache); it is given for a single page only.
///
/// [pickFolder] asks for another folder, from the one chosen; null keeps
/// the folder [parent] as it is.
Future<HtmlConvertChoice?> showHtmlConvertDialog(
  BuildContext context, {
  required List<String> sources,
  required String parent,
  String? name,
  Future<String?> Function(String current)? pickFolder,
}) => showDialog<HtmlConvertChoice>(
  context: context,
  builder: (context) => HtmlConvertDialog(
    sources: sources,
    name: name,
    parent: parent,
    pickFolder: pickFolder,
  ),
);

/// The dialog itself.
final class HtmlConvertDialog extends StatefulWidget {
  /// Asks about the pages at [sources], going into [parent] to start with.
  const new({
    required this.sources,
    required this.parent,
    this.name,
    this.pickFolder,
    super.key,
  });

  /// The pages, absolute paths.
  final List<String> sources;

  /// What a single page is called when its file is not; see
  /// [showHtmlConvertDialog].
  final String? name;

  /// The folder they go in to start with.
  final String parent;

  /// Asks for another folder; null offers none.
  final Future<String?> Function(String current)? pickFolder;

  @override
  State<HtmlConvertDialog> createState() => _HtmlConvertDialogState();
}

final class _HtmlConvertDialogState extends State<HtmlConvertDialog> {
  late String _parent = widget.parent;

  Future<void> _pick() async {
    final picked = await widget.pickFolder?.call(_parent);
    if (picked == null || !mounted) return;
    setState(() => _parent = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final many = widget.sources.length > 1;
    return AlertDialog(
      key: const Key('html-convert-dialog'),
      title: Text(AppStrings.convertTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (many) ...[
            Text(
              AppStrings.htmlConvertMany(widget.sources.length),
              style: theme.textTheme.titleMedium,
            ),
            for (final source in widget.sources)
              Text(
                p.basename(source),
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ] else
            Text(
              htmlDisplayName(widget.sources.single, widget.name),
              key: const Key('html-convert-name'),
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          ListTile(
            key: const Key('html-convert-folder'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_outlined),
            title: Text(AppStrings.convertInto),
            subtitle: Text(_parent.isEmpty ? AppStrings.libraryRoot : _parent),
            trailing: widget.pickFolder == null
                ? null
                : const Icon(Icons.chevron_right),
            onTap: widget.pickFolder == null ? null : _pick,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('html-convert-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('html-convert-start'),
          onPressed: () => Navigator.of(context).pop((parent: _parent)),
          child: Text(AppStrings.convertStart),
        ),
      ],
    );
  }
}

/// What to tell the user about [error], a conversion of the page at
/// [source] that did not happen, called [name] when its file is not.
String htmlConvertProblem(Object error, String source, {String? name}) =>
    switch (error) {
      HtmlRefused(reason: HtmlRefusal.tooLarge) =>
        AppStrings.htmlConvertTooLarge,
      HtmlRefused(reason: HtmlRefusal.unsupportedCharset) =>
        AppStrings.htmlConvertCharset,
      HtmlRefused() => AppStrings.htmlConvertUnreadable(
        htmlDisplayName(source, name),
      ),
      _ => AppStrings.htmlConvertFailed,
    };
