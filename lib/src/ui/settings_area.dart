import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// Which row the settings search landed on (issue #104): a result opens
/// its screen and the row flashes there, so the eye lands where the tap
/// pointed.
final class SettingsHighlight extends InheritedWidget {
  /// Provides the highlighted row's [target] key to the rows below.
  const new({required this.target, required super.child, super.key});

  /// The row to flash, or null for no highlight.
  final Key? target;

  /// The highlighted row's key, or null.
  static Key? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsHighlight>()?.target;

  @override
  bool updateShouldNotify(SettingsHighlight old) => old.target != target;
}

/// A settings row that flashes when the search lands on it.
///
/// Carries the row's key itself (the key moves here from the row), so
/// existing finders and taps keep working: the wrapper is transparent
/// to hits, and on mount it scrolls itself into view and flashes.
final class HighlightRow extends StatefulWidget {
  /// Wraps the row identified by [key].
  const new({required this.child, super.key});

  /// The row, keyless: the key sits on this wrapper.
  final Widget child;

  @override
  State<HighlightRow> createState() => _HighlightRowState();
}

final class _HighlightRowState extends State<HighlightRow> {
  bool _flash = false;
  Timer? _timer;
  bool _shown = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFlash());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeFlash();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Flashes once when this row is the highlight target: scrolls into
  /// view first, so a row below the fold is seen, not just lit.
  ///
  /// Always after layout: [Scrollable.ensureVisible] needs the
  /// scrollable laid out, which it is not while this row mounts.
  void _maybeFlash() {
    if (_shown || _scheduled || !mounted) return;
    if (SettingsHighlight.of(context) != widget.key) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_shown || !mounted) return;
      if (SettingsHighlight.of(context) != widget.key) return;
      _shown = true;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
      );
      setState(() => _flash = true);
      _timer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _flash = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // The inner Material carries the ListTile's inks: without it the
    // flash's ColoredBox would hide them, which the framework asserts
    // on.
    return ColoredBox(
      color: _flash
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: Material(type: MaterialType.transparency, child: widget.child),
    );
  }
}

/// The frame every settings area screen wears (issue #104): the app bar
/// with back, the area's title, and — for a library area — the library's
/// name under it, over the screen's rows.
///
/// [highlight] is the row the settings search landed on: it scrolls
/// into view and flashes once.
final class SettingsAreaShell extends StatelessWidget {
  /// Creates the frame for [title]'s rows.
  const new({
    required this.title,
    required this.controller,
    required this.body,
    this.library,
    this.highlight,
    super.key,
  });

  /// The area's name, the app bar's title.
  final String title;

  /// The session the screen edits; the library's name comes from it.
  final LibrarySession controller;

  /// Whether this is a library area: the name goes under the title, so
  /// a library setting cannot be changed for the wrong library.
  final bool? library;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  /// The screen's rows.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final library = this.library;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: library == true
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    AppStrings.settingsGroupLibrary(
                      p.basename(controller.root ?? ''),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(title),
      ),
      body: SettingsHighlight(target: highlight, child: body),
    );
  }
}
