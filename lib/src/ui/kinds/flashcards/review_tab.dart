import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// The study a wide window shows as a tab of its panes (#533, decision 9):
/// beside the deck, in the other pane, its chip at the end of that pane's
/// row as the history's compare tab has (#712).
///
/// The starter hands it a run; the shell, which [hosted] says is there,
/// picks the pane and draws it. The study goes on while a note tab covers
/// it, until its ✕, **Back to the deck** or `Esc`.
final class ReviewTab extends ChangeNotifier {
  ReviewRun? _run;
  bool _shows = false;

  /// The pane it opened in; null until the shell places it there.
  int? pane;

  /// Whether a wide shell draws the tab: without one the study is full
  /// screen.
  bool hosted = false;

  /// The study, or null when none is open.
  ReviewRun? get run => _run;

  /// Whether it is what its pane shows, rather than a note tab.
  bool get shows => _shows && _run != null;

  /// Opens [run], in [pane] when given (the next deck's study takes the
  /// place of the last), else where the shell places it.
  void open(ReviewRun run, {int? pane}) {
    _run = run;
    this.pane = pane;
    _shows = true;
    notifyListeners();
  }

  /// Shows it, or lets a note tab cover it.
  void show({bool on = true}) {
    if (_shows == on) return;
    _shows = on;
    notifyListeners();
  }

  /// Ends the study.
  void close() {
    if (_run == null) return;
    _run = null;
    pane = null;
    _shows = false;
    notifyListeners();
  }
}

/// The open study's tab, for the shell and the deck it marks.
final reviewTabProvider = Provider<ReviewTab>((ref) {
  final tab = ReviewTab();
  ref.onDispose(tab.dispose);
  return tab;
});

/// The study tab's chip (#712's shape): `Study · Irregular verbs`, a click
/// shows it again, the ✕ ends the study.
final class ReviewTabChip extends StatelessWidget {
  /// The chip of the study called [title].
  const new({
    required this.title,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.onClose,
    super.key,
  });

  /// The deck's name.
  final String title;

  /// Whether the pane shows the study.
  final bool selected;

  /// Whether the pane has the focus.
  final bool focused;

  /// Shows the study.
  final VoidCallback onTap;

  /// Ends it.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colour = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
      child: TabSurface(
        key: const Key('review-tab'),
        selected: selected,
        focused: focused,
        onTap: onTap,
        builder: (context, {required hover}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Icon(Icons.style_outlined, size: 15, color: colour),
            const SizedBox(width: 6),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  AppStrings.flashcardsReviewTitle(title),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: colour),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox.square(
              dimension: TabSurface.closeFor(touch: thumbDense(theme)),
              child: IconButton(
                key: const Key('review-tab-close'),
                tooltip: AppStrings.flashcardsEndReview,
                padding: EdgeInsets.zero,
                iconSize: 14,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
