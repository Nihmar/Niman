import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The frame around the sync settings: a page with an app bar carrying
/// the title and the library, or, inside a floating window (#712) whose
/// header carries the title, the library's line over the body.
final class SyncSettingsFrame extends StatelessWidget {
  /// The frame around [body] for the library named [libraryName].
  const new({
    required this.libraryName,
    required this.embedded,
    required this.body,
    super.key,
  });

  /// Shown under the title.
  final String libraryName;

  /// Whether the settings are drawn inside a floating window.
  final bool embedded;

  /// The form or the overview.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              AppStrings.syncScreenSubtitle(libraryName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.syncWebDavTitle),
            Text(
              AppStrings.syncScreenSubtitle(libraryName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}
