/// The first-run welcome deck (#266): what Niman can do, one theme at a
/// time, and the Markdown question that decides how the first library
/// opens.
///
/// The deck is read-only from Settings → About (`readOnly: true`): the
/// question is not asked twice and never rewrites an existing library.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/ui/welcome/welcome_copy.dart';
import 'package:niman/src/ui/welcome/welcome_pages.dart';

/// The welcome deck.
final class WelcomeScreen extends StatefulWidget {
  /// Creates the interactive deck.
  const new({
    this.onAnswer,
    this.onFinish,
    this.copy = const WelcomeCopy(),
    this.readOnly = false,
    this.onClose,
    this.initialAnswer,
    this.initialTourOffer = false,
    super.key,
  });

  /// The words; a constant, and a seam for a test that wants its own.
  final WelcomeCopy copy;

  /// Whether this is the read-only deck (no question, no tour offer, a
  /// Close button).
  final bool readOnly;

  /// Called when an answer is tapped, at once: a deck left halfway keeps
  /// what it was told.
  final ValueChanged<MarkdownExperience>? onAnswer;

  /// Called when the deck is left: what was answered (null when skipped),
  /// and whether the tour was asked for.
  final void Function({
    required MarkdownExperience? experience,
    required bool tourOffer,
  })?
  onFinish;

  /// Called by the read-only deck's Close button (null shows none).
  final VoidCallback? onClose;

  /// The answer already stored, when the deck is opened again read-only.
  final MarkdownExperience? initialAnswer;

  /// Whether the tour was already asked for.
  final bool initialTourOffer;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

final class _WelcomeScreenState extends State<WelcomeScreen> {
  /// The pages, rebuilt from the copy: a widget pumped again with other
  /// words gets them.
  List<WelcomePage> get _pages => [
    ...themedPages(widget.copy),
    devicePage(widget.copy),
  ];

  int _page = 0;
  MarkdownExperience? _answer;
  late bool _tourOffer = widget.initialTourOffer;

  @override
  void initState() {
    super.initState();
    _answer = widget.initialAnswer;
  }

  /// The question is a page of its own, after the device page.
  int get _questionPage => _pages.length;
  int get _lastPage => widget.readOnly ? _pages.length - 1 : _questionPage;
  bool get _onQuestion => !widget.readOnly && _page == _questionPage;

  void _next() {
    if (_page < _lastPage) setState(() => _page++);
  }

  void _back() {
    if (_page > 0) setState(() => _page--);
  }

  void _choose(MarkdownExperience answer) {
    setState(() => _answer = answer);
    widget.onAnswer?.call(answer);
  }

  void _finish() =>
      widget.onFinish?.call(experience: _answer, tourOffer: _tourOffer);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.pageDown:
        _next();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.pageUp:
        _back();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        // Esc leaves: the deck finishes as a skip; the read-only deck
        // closes where it has somewhere to go back to.
        if (!widget.readOnly) {
          _finish();
          return KeyEventResult.handled;
        }
        final onClose = widget.onClose;
        if (onClose == null) return KeyEventResult.ignored;
        onClose();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Android's back goes a page back, and leaves the app from the first
    // page (with the deck unfinished, so it returns next launch).
    return PopScope(
      canPop: _page == 0 || widget.readOnly,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(theme),
                      Expanded(
                        child: SingleChildScrollView(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _onQuestion
                                ? _question(theme)
                                : _prose(theme, _pages[_page]),
                          ),
                        ),
                      ),
                      _footer(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Skip (or Close, read-only) at the top right.
  Widget _header(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.readOnly)
          TextButton(
            key: const Key('welcome-close'),
            onPressed: widget.onClose,
            child: Text(widget.copy.close),
          )
        else
          TextButton(
            key: const Key('welcome-skip'),
            onPressed: _finish,
            child: Text(widget.copy.skip),
          ),
      ],
    );
  }

  /// One prose page: its heading and its body.
  Widget _prose(ThemeData theme, WelcomePage page) {
    return Column(
      key: ValueKey<int>(_page),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          page.title,
          key: const Key('welcome-title'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          page.body,
          key: const Key('welcome-body'),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// The last page: the Markdown question, the tour offer, and Start.
  Widget _question(ThemeData theme) {
    return Column(
      key: const ValueKey<int>(-1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          widget.copy.questionTitle,
          key: const Key('welcome-question'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        RadioGroup<MarkdownExperience>(
          groupValue: _answer,
          onChanged: (value) => value == null ? null : _choose(value),
          child: Column(
            children: [
              _answerTile(
                MarkdownExperience.none,
                widget.copy.answerNone,
                widget.copy.answerNoneHint,
              ),
              _answerTile(
                MarkdownExperience.some,
                widget.copy.answerSome,
                widget.copy.answerSomeHint,
              ),
              _answerTile(
                MarkdownExperience.fluent,
                widget.copy.answerFluent,
                widget.copy.answerFluentHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.copy.questionNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          key: const Key('welcome-tour-offer'),
          value: _tourOffer,
          onChanged: (value) => setState(() => _tourOffer = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(widget.copy.tourOffer),
          subtitle: Text(widget.copy.tourOfferNote),
        ),
      ],
    );
  }

  Widget _answerTile(MarkdownExperience answer, String label, String hint) {
    return RadioListTile<MarkdownExperience>(
      key: Key('welcome-answer-${answer.id}'),
      value: answer,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(hint),
    );
  }

  /// The dots, Back, and Next (or Start; Close on the read-only deck's
  /// last page — a Next there would be a control that does nothing).
  Widget _footer(ThemeData theme) {
    final last = _onQuestion || (widget.readOnly && _page == _lastPage);
    return Row(
      children: [
        Semantics(
          label: widget.copy.pageOf(_page + 1, _lastPage + 1),
          child: Row(
            children: [
              for (var i = 0; i <= _lastPage; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        if (_page > 0)
          TextButton(
            key: const Key('welcome-back'),
            onPressed: _back,
            child: Text(widget.copy.back),
          ),
        const SizedBox(width: 8),
        FilledButton(
          key: Key(
            last
                ? (widget.readOnly ? 'welcome-close-primary' : 'welcome-start')
                : 'welcome-next',
          ),
          onPressed: last
              ? (widget.readOnly ? widget.onClose : _finish)
              : _next,
          child: Text(
            last
                ? (widget.readOnly ? widget.copy.close : widget.copy.start)
                : widget.copy.next,
          ),
        ),
      ],
    );
  }
}
