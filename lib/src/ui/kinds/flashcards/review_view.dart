import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/kinds/flashcards/card_text.dart';
import 'package:niman/src/ui/kinds/flashcards/next_label.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/kinds/flashcards/review_summary_view.dart';
import 'package:niman/src/ui/strings.dart';

/// A study (mockups D2–D4, P4–P6): the question, **Show answer**, then the
/// four grades, each with when it brings the card back; the progress, the
/// cards left, undo; and the summary once the queue is empty.
///
/// Keys: `Space` shows the answer, then grades Good; `1`–`4` grade once it
/// shows; `Ctrl+Z` undoes; `Esc` ends.
final class ReviewView extends StatefulWidget {
  /// The view of [run].
  const new({
    required this.run,
    required this.onClose,
    required this.onNextDeck,
    super.key,
  });

  /// The study.
  final ReviewRun run;

  /// Ends the study: `Esc`, the ✕, **Back to the deck**.
  final VoidCallback onClose;

  /// Studies the deck at the library-relative path, **Next deck**.
  final ValueChanged<String> onNextDeck;

  @override
  State<ReviewView> createState() => _ReviewViewState();
}

final class _ReviewViewState extends State<ReviewView> {
  final MathCache _math = MathCache();
  final FocusNode _focus = FocusNode(debugLabel: 'review');

  @override
  void initState() {
    super.initState();
    // Asked once the frame is drawn: a shell that takes the keys back when
    // a pane changes (#770) has had its turn by then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _math.dispose();
    super.dispose();
  }

  static final Map<LogicalKeyboardKey, Grade> _gradeKeys = {
    LogicalKeyboardKey.digit1: Grade.again,
    LogicalKeyboardKey.digit2: Grade.hard,
    LogicalKeyboardKey.digit3: Grade.good,
    LogicalKeyboardKey.digit4: Grade.easy,
    LogicalKeyboardKey.numpad1: Grade.again,
    LogicalKeyboardKey.numpad2: Grade.hard,
    LogicalKeyboardKey.numpad3: Grade.good,
    LogicalKeyboardKey.numpad4: Grade.easy,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final run = widget.run;
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
    } else if (key == LogicalKeyboardKey.keyZ &&
        (keyboard.isControlPressed || keyboard.isMetaPressed)) {
      run.undo();
    } else if (key == LogicalKeyboardKey.space) {
      run.session.answerShown ? run.grade(Grade.good) : run.show();
    } else if (_gradeKeys[key] case final grade?) {
      run.grade(grade);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: _onKey,
    child: ListenableBuilder(
      listenable: widget.run,
      builder: (context, _) {
        final session = widget.run.session;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _top(context),
            LinearProgressIndicator(
              key: const Key('review-progress'),
              // Every grade given can be taken back: [undoable] counts them.
              value: session.isDone
                  ? 1
                  : session.undoable / (session.undoable + session.remaining),
              minHeight: 2,
            ),
            Expanded(
              child: session.isDone
                  ? ReviewSummaryView(
                      run: widget.run,
                      onBack: widget.onClose,
                      onNextDeck: widget.onNextDeck,
                    )
                  : _card(context),
            ),
            if (!session.isDone) _bottom(context),
          ],
        );
      },
    ),
  );

  Widget _top(BuildContext context) {
    final session = widget.run.session;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final counts = session.isDone
        ? ''
        : [
            AppStrings.flashcardsDueCount(session.remainingDue),
            AppStrings.flashcardsNewCount(session.remainingNew),
            AppStrings.flashcardsAgainCount(session.remainingAgain),
          ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      child: Row(
        children: [
          // The counts under the name: beside it, a phone's width has no
          // room for both and the two buttons.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.flashcardsReviewTitle(widget.run.title),
                  key: const Key('review-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (counts.isNotEmpty)
                  Text(
                    counts,
                    key: const Key('review-counts'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('review-undo'),
            tooltip: AppStrings.actionUndo,
            icon: const Icon(Icons.undo),
            onPressed: session.undoable > 0 ? widget.run.undo : null,
          ),
          IconButton(
            key: const Key('review-close'),
            tooltip: AppStrings.flashcardsEndReview,
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context) {
    final session = widget.run.session;
    final card = session.current!.card;
    final cloze = card.kind == CardKind.cloze;
    final theme = Theme.of(context);
    final big = theme.textTheme.headlineSmall?.copyWith(fontFamily: 'Literata');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A cloze's answer is its sentence with the gap filled in.
              if (!(cloze && session.answerShown))
                CardText(
                  card.question,
                  key: const Key('review-question'),
                  mathCache: _math,
                  style: big,
                  cloze: cloze,
                ),
              if (session.answerShown) ...[
                if (!cloze) const Divider(height: 48),
                CardText(
                  cloze
                      ? card.question.replaceFirst(
                          FlashCard.clozeGap,
                          '==${card.answer}==',
                        )
                      : card.answer,
                  key: const Key('review-answer'),
                  mathCache: _math,
                  style: big,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottom(BuildContext context) {
    final session = widget.run.session;
    final keys = !isPhone(context);
    if (!session.answerShown) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('review-show'),
          onPressed: widget.run.show,
          child: Text(
            keys
                ? '${AppStrings.flashcardsShowAnswer}  ·  Space'
                : AppStrings.flashcardsShowAnswer,
          ),
        ),
      );
    }
    final previews = session.previews;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (final (index, grade) in Grade.values.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _GradeButton(
                  grade: grade,
                  when: comesBackLabel(previews[grade] ?? 0),
                  shortcut: keys ? '${index + 1}' : null,
                  onPressed: () => widget.run.grade(grade),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One of the four grades: its name, when it brings the card back, and
/// its key where there is a keyboard.
final class _GradeButton extends StatelessWidget {
  const new({
    required this.grade,
    required this.when,
    required this.shortcut,
    required this.onPressed,
  });

  final Grade grade;
  final String when;
  final String? shortcut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return OutlinedButton(
      key: Key('review-grade-${grade.name}'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        foregroundColor: grade == Grade.again ? scheme.error : null,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(gradeName(grade), overflow: TextOverflow.ellipsis),
          Text(when, style: small, overflow: TextOverflow.ellipsis),
          if (shortcut case final key?) Text(key, style: small),
        ],
      ),
    );
  }
}
