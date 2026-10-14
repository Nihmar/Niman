import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/study_session.dart';
import 'package:niman/src/ui/kinds/flashcards/next_label.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/strings.dart';

/// The end of a study (mockups D4, P6): the cards reviewed, the Again
/// grades, the time, the grades' spread, when the next cards are due, and
/// **Back to the deck** beside **Next deck**.
final class ReviewSummaryView extends StatefulWidget {
  /// The end of [run].
  const new({
    required this.run,
    required this.onBack,
    required this.onNextDeck,
    super.key,
  });

  /// The study, done.
  final ReviewRun run;

  /// **Back to the deck**.
  final VoidCallback onBack;

  /// **Next deck**, with the deck's library-relative path.
  final ValueChanged<String> onNextDeck;

  @override
  State<ReviewSummaryView> createState() => _ReviewSummaryViewState();
}

final class _ReviewSummaryViewState extends State<ReviewSummaryView> {
  /// The deck **Next deck** studies, looked for once.
  late final Future<String?> _next =
      widget.run.nextDeck?.call() ?? Future.value();

  @override
  Widget build(BuildContext context) {
    final summary = widget.run.session.summary;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final minutes = (summary.elapsed.inSeconds / 60).ceil();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.flashcardsDoneToday,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              [
                AppStrings.flashcardsReviewedCount(summary.reviewed),
                AppStrings.flashcardsAgainCount(summary.again),
                AppStrings.flashcardsMinutes(minutes < 1 ? 1 : minutes),
              ].join(' · '),
              key: const Key('review-summary-counts'),
              style: muted,
            ),
            const SizedBox(height: 16),
            _Spread(summary.grades),
            const SizedBox(height: 16),
            Text(
              _nextLine(summary, widget.run.session.today),
              key: const Key('review-summary-next'),
              style: muted,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  key: const Key('review-back'),
                  onPressed: widget.onBack,
                  child: Text(AppStrings.flashcardsBackToDeck),
                ),
                FutureBuilder(
                  future: _next,
                  builder: (context, next) => FilledButton(
                    key: const Key('review-next-deck'),
                    onPressed: next.data == null
                        ? null
                        : () => widget.onNextDeck(next.data!),
                    child: Text(AppStrings.flashcardsNextDeck),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// `Next: tomorrow · 12 cards`, from the study day [today].
  static String _nextLine(SessionSummary summary, DateTime today) {
    final next = summary.nextDue;
    if (next == null) return AppStrings.flashcardsNothingScheduled;
    // Calendar days, in UTC: a day of 23 or 25 hours counts as one.
    final days = DateTime.utc(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    return '${AppStrings.flashcardsNextOn(comesBackLabel(days))} · '
        '${AppStrings.flashcardsCardCount(summary.nextCount)}';
  }
}

/// How many times each grade was given, in a row of four.
final class _Spread extends StatelessWidget {
  const new(this.grades);

  final Map<Grade, int> grades;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      key: const Key('review-summary-spread'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final grade in Grade.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  '${grades[grade] ?? 0}',
                  style: theme.textTheme.titleLarge,
                ),
                Text(gradeName(grade), style: small),
              ],
            ),
          ),
      ],
    );
  }
}
