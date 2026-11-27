/// The look-up panel (#1383): what a selection means, drawn the same on a
/// phone's sheet and a desktop's panel.
///
/// A header with the headword (the lemma) and the form read that led to it,
/// and the language chip; a body that is the entries, or what stands in
/// their place; a foot with the pack's name and licence and the two actions,
/// Copy and Annotate with the definition. The icons stay where they are
/// whatever the answer, greyed when there is nothing to copy or annotate.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/dictionary/dictionary_entry_group.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_language.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/ui/dictionaries/dictionary_names.dart';
import 'package:niman/src/ui/dictionary_panel/definition_text.dart';
import 'package:niman/src/ui/dictionary_panel/entry_view.dart';
import 'package:niman/src/ui/dictionary_panel/language_chooser.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_no_pack.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_session.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_states.dart';
import 'package:niman/src/ui/strings.dart';

/// Annotates the passage with [definition], the text of the look-up.
typedef DictionaryAnnotate = Future<void> Function(String definition);

/// The panel's content over [session].
final class DictionaryPanel extends StatefulWidget {
  /// Draws [session]'s answer. [installation] is what a download goes
  /// through; [annotate] is null where the surface cannot annotate, and
  /// the icon is then greyed; [onClose] closes whatever holds the panel and
  /// [onOpenSettings] opens Settings → Dictionaries.
  ///
  /// [compact] is the desktop's panel, a size smaller; [fill] stretches the
  /// body to the room it is given (a sheet), where it otherwise takes what
  /// it needs. [scroll] is the body's scroll controller, for a sheet that
  /// is dragged higher.
  const new({
    required this.session,
    required this.installation,
    required this.onClose,
    required this.onOpenSettings,
    this.annotate,
    this.compact = false,
    this.fill = false,
    this.scroll,
    super.key,
  });

  /// The look-ups of the panel.
  final DictionaryLookupSession session;

  /// What the device has, and the downloads under way.
  final DictionaryInstallation installation;

  /// Annotates the passage with the definition; null cannot.
  final DictionaryAnnotate? annotate;

  /// Closes the panel.
  final VoidCallback onClose;

  /// Opens Settings → Dictionaries.
  final VoidCallback onOpenSettings;

  /// Whether this is the desktop's small panel.
  final bool compact;

  /// Whether the body fills the room it has.
  final bool fill;

  /// The body's scroll controller.
  final ScrollController? scroll;

  @override
  State<DictionaryPanel> createState() => _DictionaryPanelState();
}

final class _DictionaryPanelState extends State<DictionaryPanel> {
  /// Whether the definition was just copied: the icon says so until the
  /// look-up changes.
  bool _copied = false;
  DictionaryResult? _seen;

  double get _size => widget.compact ? 13.5 : 15;

  void _changed() {
    if (_seen != widget.session.result) {
      _seen = widget.session.result;
      _copied = false;
    }
  }

  /// Whether the body lists the languages instead of the answer.
  bool _choosing = false;

  /// Opens the list of languages, or closes it: the chip is its switch.
  void _toggleLanguages() => setState(() => _choosing = !_choosing);

  void _choose(String code) {
    setState(() => _choosing = false);
    unawaited(widget.session.changeLanguage(code));
  }

  Set<String> get _installedLanguages => {
    for (final pack in widget.installation.installed)
      if (pack.pack.isAvailable) ...pack.pack.languages,
  };

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _copied = true);
  }

  void _annotate(DictionaryAnnotate annotate, String text) {
    widget.onClose();
    unawaited(annotate(text));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      _changed();
      final theme = Theme.of(context);
      final session = widget.session;
      final result = session.result;
      final groups = session.groups;
      final text = groups.isEmpty ? '' : DefinitionText.of(groups);
      final annotate = widget.annotate;
      final pad = widget.compact ? 16.0 : 20.0;
      return Column(
        mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            session: session,
            padding: pad,
            compact: widget.compact,
            onChooseLanguage: _toggleLanguages,
          ),
          const Divider(height: 1),
          Flexible(
            fit: widget.fill ? FlexFit.tight : FlexFit.loose,
            child: SingleChildScrollView(
              key: const Key('lookup-body'),
              controller: widget.scroll,
              // A sheet is dragged by its body, whatever the body's length.
              physics: widget.scroll == null
                  ? null
                  : const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 12),
              child: _choosing
                  ? LookupLanguageList(
                      installed: _installedLanguages,
                      current: session.language,
                      onChosen: _choose,
                    )
                  : _body(session, result, groups),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsetsDirectional.only(start: pad, end: 6, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _credit(groups),
                    key: const Key('lookup-credit'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('lookup-copy'),
                  tooltip: AppStrings.lookUpCopy,
                  icon: Icon(
                    _copied ? Icons.check : Icons.content_copy_outlined,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: text.isEmpty ? null : () => unawaited(_copy(text)),
                ),
                IconButton(
                  key: const Key('lookup-annotate'),
                  tooltip: AppStrings.lookUpAnnotate,
                  icon: const Icon(Icons.edit_note),
                  visualDensity: VisualDensity.compact,
                  onPressed: text.isEmpty || annotate == null
                      ? null
                      : () => _annotate(annotate, text),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  /// The pack's name and licence: what the first entry says it comes from.
  String _credit(List<DictionaryEntryGroup> groups) {
    if (groups.isEmpty) return '';
    final credit = groups.first.entry.credit;
    return [
      credit.bookName,
      credit.license,
    ].where((s) => s.isNotEmpty).join(' · ');
  }

  Widget _body(
    DictionaryLookupSession session,
    DictionaryResult? result,
    List<DictionaryEntryGroup> groups,
  ) {
    if (result == null) return LookupLoading(indexed: session.indexed);
    switch (result.outcome) {
      case DictionaryOutcome.found:
        return Column(
          key: const Key('lookup-entries'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, group) in groups.indexed) ...[
              if (i > 0) const Divider(height: 20),
              EntryView(
                group: group,
                heading: i > 0,
                onFollow: (word) => unawaited(session.follow(word)),
                fontSize: _size,
              ),
            ],
          ],
        );
      case DictionaryOutcome.notFound:
        return LookupNotFound(
          result: result,
          onFollow: (word) => unawaited(session.follow(word)),
          fontSize: _size,
        );
      case DictionaryOutcome.noPack:
        return LookupNoPack(
          result: result,
          installation: widget.installation,
          onReady: () => unawaited(session.refresh()),
          onChangeLanguage: _toggleLanguages,
          fontSize: _size,
        );
      case DictionaryOutcome.unavailable:
        return LookupUnavailable(
          result: result,
          onOpenSettings: widget.onOpenSettings,
          fontSize: _size,
        );
    }
  }
}

/// The panel's title: the lemma and what led to it, a way back, and the
/// language chip.
final class _Header extends StatelessWidget {
  const new({
    required this.session,
    required this.padding,
    required this.compact,
    required this.onChooseLanguage,
  });

  final DictionaryLookupSession session;
  final double padding;
  final bool compact;
  final VoidCallback onChooseLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = session.result;
    final groups = session.groups;
    final code =
        DictionaryLanguage.normalise(session.language) ?? session.language;
    final language = DictionaryNames.native(code);
    final title = groups.isEmpty
        ? session.selection
        : groups.first.entry.headword;
    final subtitle = switch (result?.outcome) {
      DictionaryOutcome.found =>
        foundFormLine(groups.first.entry.foundForm) ?? language,
      DictionaryOutcome.notFound => AppStrings.lookUpNoDefinition(language),
      _ => language,
    };
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        session.canGoBack ? 4 : padding,
        compact ? 10 : 4,
        padding,
        10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (session.canGoBack)
            IconButton(
              key: const Key('lookup-back'),
              tooltip: AppStrings.lookUpBack,
              icon: const Icon(Icons.arrow_back),
              visualDensity: VisualDensity.compact,
              onPressed: () => unawaited(session.back()),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('lookup-title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 20 : 24,
                  ),
                ),
                Text(
                  subtitle,
                  key: const Key('lookup-subtitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              key: const Key('lookup-language'),
              borderRadius: BorderRadius.circular(16),
              onTap: onChooseLanguage,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(language, style: theme.textTheme.bodySmall),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
