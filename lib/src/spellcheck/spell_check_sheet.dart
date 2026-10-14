/// The spelling review panel (T-PP-09).
///
/// Lists the note's misspellings with hunspell's suggestions; tapping a
/// suggestion replaces the word in place through the editor's controller.
/// Built over closures so it owns no editor state.
///
/// It opens at once on any note (#61). The whole-note pass runs a slice
/// at a time and the list fills as it goes, with a bar for how far it
/// got. Suggestions — hunspell's slow call — come one word at a time
/// after the list, so no single frame pays for them all. A fix updates
/// the list in place instead of checking the note again: the note does
/// not change under a modal panel, so the other issues stand, and the
/// ones after the fix on its line only move over.
///
/// Docked beside the note on a desktop (#712) it is not modal: the note
/// changes under it, so it checks the note again after each edit (once the
/// writer pauses), a click on an issue selects the word in the note, and
/// each issue can be ignored or added to the library's dictionary.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/strings.dart';

/// A bottom sheet over the open note listing its spelling issues, or the
/// dock's pane beside it ([docked]).
final class SpellCheckSheet extends StatefulWidget {
  /// Creates the panel over [start], [suggest] and [apply].
  const new({
    required this.start,
    required this.suggest,
    required this.apply,
    required this.available,
    this.docked = false,
    this.reveal,
    this.addWord,
    this.edited,
    super.key,
  });

  /// Whether the panel is the dock's pane: it fills it, has no close
  /// button, and follows the note's edits.
  final bool docked;

  /// Selects an issue's word in the note; null leaves the rows unclickable.
  final void Function(SpellIssue issue)? reveal;

  /// Adds a word to the library's dictionary; null offers no such action.
  final Future<void> Function(String word)? addWord;

  /// Tells of an edit to the note, a pause after it: the note is checked
  /// again.
  final Listenable? edited;

  /// Starts a pass over the note (on open, and on Check again).
  final SpellScan Function() start;

  /// Hunspell's suggestions for a word.
  final List<String> Function(String word) suggest;

  /// Replaces `issue`'s word with `replacement` in the editor.
  final void Function(SpellIssue issue, String replacement) apply;

  /// Whether hunspell loaded; false shows the platform note.
  final bool available;

  @override
  State<SpellCheckSheet> createState() => _SpellCheckSheetState();
}

final class _SpellCheckSheetState extends State<SpellCheckSheet> {
  SpellScan? _scan;
  List<SpellIssue> _issues = const <SpellIssue>[];

  /// How many of the pass's issues are in [_issues] already. Only the
  /// new ones are appended: the list may have been fixed meanwhile, and
  /// a fix never touches a line the pass has yet to reach.
  int _taken = 0;

  /// Suggestions made so far, by word.
  final Map<String, List<String>> _suggestions = {};
  bool _suggesting = false;

  @override
  void initState() {
    super.initState();
    widget.edited?.addListener(_onEdited);
    if (widget.available) _startScan();
  }

  @override
  void didUpdateWidget(SpellCheckSheet old) {
    super.didUpdateWidget(old);
    if (old.edited != widget.edited) {
      old.edited?.removeListener(_onEdited);
      widget.edited?.addListener(_onEdited);
    }
  }

  @override
  void dispose() {
    widget.edited?.removeListener(_onEdited);
    _stopScan();
    super.dispose();
  }

  /// The note changed under the panel: the list is checked again.
  void _onEdited() {
    if (!mounted || !widget.available) return;
    setState(_startScan);
  }

  /// Drops every issue of [word] from the list: ignored here, or known
  /// now that the dictionary has it.
  void _drop(String word) {
    setState(() {
      _issues = [
        for (final issue in _issues)
          if (issue.word != word) issue,
      ];
    });
  }

  Future<void> _addWord(String word) async {
    await widget.addWord!(word);
    if (mounted) _drop(word);
  }

  void _startScan() {
    _stopScan();
    final scan = widget.start()..addListener(_onScan);
    _scan = scan;
    _issues = const <SpellIssue>[];
    _taken = 0;
    unawaited(scan.run());
  }

  void _stopScan() {
    final scan = _scan;
    if (scan == null) return;
    scan
      ..removeListener(_onScan)
      ..cancel()
      ..dispose();
    _scan = null;
  }

  void _onScan() {
    final scan = _scan;
    if (!mounted || scan == null) return;
    final found = scan.issues;
    setState(() {
      _issues = [..._issues, ...found.skip(_taken)];
      _taken = found.length;
    });
    unawaited(_suggestOnward());
  }

  /// Makes the suggestions the list still lacks, one word per turn of the
  /// event loop, in reading order.
  Future<void> _suggestOnward() async {
    if (_suggesting) return;
    _suggesting = true;
    try {
      while (mounted) {
        final word = _issues
            .map((issue) => issue.word)
            .where((word) => !_suggestions.containsKey(word))
            .firstOrNull;
        if (word == null) break;
        final suggestions = widget.suggest(word);
        if (!mounted) break;
        setState(() => _suggestions[word] = suggestions);
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      _suggesting = false;
    }
  }

  void _replace(SpellIssue issue, String replacement) {
    widget.apply(issue, replacement);
    final shift = replacement.length - (issue.end - issue.start);
    setState(() {
      _issues = [
        for (final other in _issues)
          if (identical(other, issue))
            ...const <SpellIssue>[]
          else if (other.line == issue.line && other.start >= issue.end)
            other.movedBy(shift)
          else
            other,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.docked) {
      return Column(
        children: [
          _header(context),
          _progress(context),
          Expanded(child: _body(context)),
        ],
      );
    }
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            _progress(context),
            Flexible(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.spellCheckTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (_issues.isNotEmpty)
            Text(
              AppStrings.spellCheckCount(_issues.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (!widget.docked)
            IconButton(
              key: const Key('spell-check-close'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  /// The bar while the pass runs, then a plain divider; with the list
  /// full, the line that says so and offers another pass.
  Widget _progress(BuildContext context) {
    final scan = _scan;
    if (scan != null && !scan.done) {
      return LinearProgressIndicator(
        key: const Key('spell-check-progress'),
        minHeight: 2,
        value: scan.lineCount == 0 ? null : scan.linesDone / scan.lineCount,
      );
    }
    if (scan == null || !scan.capped) return const Divider(height: 1);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          key: const Key('spell-check-capped'),
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.spellCheckCapped(EditorSpellCheck.maxIssues),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                key: const Key('spell-check-again'),
                onPressed: () => setState(_startScan),
                child: Text(AppStrings.spellCheckAgain),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (!widget.available) {
      return _message(context, AppStrings.spellCheckUnavailable);
    }
    if (_issues.isEmpty) {
      final running = !(_scan?.done ?? true);
      return _message(
        context,
        running ? AppStrings.spellCheckScanning : AppStrings.spellCheckEmpty,
      );
    }
    return ListView.separated(
      key: const Key('spell-check-list'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _issues.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _issueTile(context, _issues[index]),
    );
  }

  Widget _message(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text, textAlign: TextAlign.center),
  );

  Widget _issueTile(BuildContext context, SpellIssue issue) {
    final theme = Theme.of(context);
    final suggestions = _suggestions[issue.word];
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reveal = widget.reveal;
    final tile = Padding(
      key: Key('spell-issue-${issue.line}-${issue.start}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                issue.word,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.spellCheckLine(issue.line + 1),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (suggestions == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('…', style: muted),
            )
          else if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(AppStrings.spellCheckNoSuggestions, style: muted),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in suggestions.take(4))
                    ActionChip(
                      key: Key('suggest-$suggestion'),
                      label: Text(suggestion),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _replace(issue, suggestion),
                    ),
                ],
              ),
            ),
          if (widget.docked)
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  key: Key('spell-ignore-${issue.line}-${issue.start}'),
                  onPressed: () => _drop(issue.word),
                  child: Text(AppStrings.spellCheckIgnore),
                ),
                if (widget.addWord != null)
                  TextButton(
                    key: Key('spell-add-${issue.line}-${issue.start}'),
                    onPressed: () => unawaited(_addWord(issue.word)),
                    child: Text(AppStrings.addWordToDictionary),
                  ),
              ],
            ),
        ],
      ),
    );
    if (reveal == null) return tile;
    return InkWell(onTap: () => reveal(issue), child: tile);
  }
}
