import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:niman/src/core/changelog.dart';
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: changelogEntryBlock(context, entry),
                ),
            ],
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
                  child: changelogEntryBlock(context, entry),
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
Widget changelogEntryBlock(BuildContext context, ChangelogVersion entry) {
  final theme = Theme.of(context);
  final date = entry.date;
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
        for (final item in section.items)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•'),
                const SizedBox(width: 6),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    ],
  );
}
