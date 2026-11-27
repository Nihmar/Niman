import 'package:flutter/material.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/ui/dictionaries/dictionary_names.dart';
import 'package:niman/src/ui/strings.dart';

/// The wait for a look-up: a spinner, and how far the index the first
/// look-up in a pack builds has got, when it waits for one.
final class LookupLoading extends StatelessWidget {
  /// The wait; [indexed] is the index's progress, 0 to 1, or null.
  const new({this.indexed, super.key});

  /// How far the index is built, or null when none is.
  final double? indexed;

  @override
  Widget build(BuildContext context) {
    final indexed = this.indexed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(value: indexed, strokeWidth: 3),
          ),
          if (indexed != null) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.dictionaryIndexing((indexed * 100).floor()),
              key: const Key('lookup-indexing'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Nothing found: the nearest entries, which look themselves up
/// (screen E). Nothing goes anywhere else.
final class LookupNotFound extends StatelessWidget {
  /// The answer [result] says nothing was found, [onFollow] looks one of its
  /// suggestions up.
  const new({
    required this.result,
    required this.onFollow,
    required this.fontSize,
    super.key,
  });

  /// The look-up that found nothing.
  final DictionaryResult result;

  /// Looks a suggestion up.
  final ValueChanged<String> onFollow;

  /// The size of the body text.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final language = DictionaryNames.native(result.language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.lookUpNotFound(language),
          key: const Key('lookup-not-found'),
          style: TextStyle(fontSize: fontSize, height: 1.4),
        ),
        if (result.suggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            AppStrings.lookUpDidYouMean,
            style: TextStyle(fontSize: fontSize - 1, color: muted),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              for (final word in result.suggestions)
                TextButton(
                  key: Key('lookup-suggestion-$word'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: TextStyle(fontSize: fontSize),
                  ),
                  onPressed: () => onFollow(word),
                  child: Text(word),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A dictionary that is there and cannot be used: why, and the way to the
/// page that can mend it.
final class LookupUnavailable extends StatelessWidget {
  /// The answer [result] says the pack cannot be used; [onOpenSettings]
  /// opens Settings → Dictionaries.
  const new({
    required this.result,
    required this.onOpenSettings,
    required this.fontSize,
    super.key,
  });

  /// The look-up that could not be made.
  final DictionaryResult result;

  /// Opens the Dictionaries settings.
  final VoidCallback onOpenSettings;

  /// The size of the body text.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final reason = result.reason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.lookUpUnavailable(DictionaryNames.native(result.language)),
          key: const Key('lookup-unavailable'),
          style: TextStyle(fontSize: fontSize, height: 1.4),
        ),
        if (reason != null && reason.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            AppStrings.dictionaryUnusable(reason),
            style: TextStyle(fontSize: fontSize - 1, color: muted),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const Key('lookup-open-settings'),
            onPressed: onOpenSettings,
            child: Text(AppStrings.lookUpOpenSettings),
          ),
        ),
      ],
    );
  }
}
