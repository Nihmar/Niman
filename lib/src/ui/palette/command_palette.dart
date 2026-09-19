/// The command palette (#155): one field over whatever is on screen,
/// searching the app's commands and the library's notes by name at once.
///
/// Typing filters both; ↑↓ move, ↵ runs the command or opens the note,
/// esc dismisses — the footer says so, so nobody has to be taught it.
/// With nothing typed it offers what was used last, commands and notes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/palette/palette_match.dart';
import 'package:niman/src/ui/palette/pinned_commands.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What was picked.
sealed class PaletteChoice {
  const new();
}

/// A command, to run.
final class PaletteCommandChoice extends PaletteChoice {
  /// Picked [command].
  const new(this.command);

  /// The command.
  final AppCommand command;
}

/// A note, to open.
final class PaletteNoteChoice extends PaletteChoice {
  /// Picked the note at library-relative [path].
  const new(this.path);

  /// The note.
  final String path;
}

/// Shows the palette and resolves to what was picked, or null.
///
/// [commands] are the ones that can run here and now; [notesOnly] is
/// Go to note's palette, with the commands left out. [onTogglePin] pins
/// and unpins a command (#208); null leaves the pins out.
Future<PaletteChoice?> showCommandPalette(
  BuildContext context, {
  required List<PaletteCommand> commands,
  required Future<List<String>> Function(String query) searchNotes,
  List<AppCommand> recentCommands = const [],
  List<String> recentNotes = const [],
  bool notesOnly = false,
  void Function(AppCommand command)? onTogglePin,
}) {
  return showGeneralDialog<PaletteChoice>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, _, _) => CommandPalette(
      commands: notesOnly ? const [] : commands,
      searchNotes: searchNotes,
      recentCommands: recentCommands,
      recentNotes: recentNotes,
      onTogglePin: notesOnly ? null : onTogglePin,
    ),
  );
}

/// The palette's panel.
final class CommandPalette extends StatefulWidget {
  /// A palette over [commands] and the notes [searchNotes] finds.
  const new({
    required this.commands,
    required this.searchNotes,
    this.recentCommands = const [],
    this.recentNotes = const [],
    this.onTogglePin,
    super.key,
  });

  /// The commands on offer.
  final List<PaletteCommand> commands;

  /// Finds notes by name.
  final Future<List<String>> Function(String query) searchNotes;

  /// Commands used lately, most recent first.
  final List<AppCommand> recentCommands;

  /// Notes opened lately, most recent first.
  final List<String> recentNotes;

  /// Pins or unpins a command (#208); null leaves the pins out (Go to
  /// note's palette, which has no commands).
  final void Function(AppCommand command)? onTogglePin;

  /// How wide the panel runs.
  static const double width = 620;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

final class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _query = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<PaletteCommand> _commands = const [];
  List<String> _notes = const [];
  int _selected = 0;
  int _token = 0;
  Timer? _debounce;

  /// Set once something was picked: Enter can arrive both as a key and
  /// as the field's submit, and the second must not pop the screen below.
  bool _chosen = false;

  @override
  void initState() {
    super.initState();
    _commands = _rankCommands('');
    _notes = widget.recentNotes.take(8).toList();
    // A pin from a row re-ranks the list under it (#208): the row moves
    // to the pinned head, or leaves it, without reopening the palette.
    PinnedCommands.current.addListener(_onPins);
  }

  void _onPins() {
    if (mounted) setState(() => _commands = _rankCommands(_query.text));
  }

  List<PaletteCommand> _rankCommands(String query) {
    final ranked = paletteRank(
      widget.commands,
      query,
      name: (c) => c.name,
      id: (c) => c.command,
      recent: widget.recentCommands,
    );
    if (query.trim().isEmpty) {
      // Pinned first, in pinning order, then what was used lately (#208).
      // A pinned command that cannot run here is not among [commands],
      // so it is not listed: the palette offers only what can run.
      final pinned = [
        for (final command in PinnedCommands.current.value)
          ?ranked.where((c) => c.command == command).firstOrNull,
      ];
      return [
        ...pinned,
        ...ranked.where((c) => !pinned.contains(c)),
      ].take(8 + pinned.length).toList();
    }
    return ranked.take(12).toList();
  }

  /// How many of [_commands] are the pinned ones at the head: what the
  /// PINNED heading covers.
  int get _pinnedShown {
    if (_query.text.trim().isNotEmpty) return 0;
    var count = 0;
    for (final command in _commands) {
      if (!PinnedCommands.isPinned(command.command)) break;
      count++;
    }
    return count;
  }

  /// Pins or unpins the command at [index] of the list, if it is one.
  void _togglePin(int index) {
    final onTogglePin = widget.onTogglePin;
    if (onTogglePin == null) return;
    final items = _items;
    if (index < 0 || index >= items.length) return;
    if (items[index] case PaletteCommandChoice(:final command)) {
      onTogglePin(command);
    }
  }

  @override
  void dispose() {
    PinnedCommands.current.removeListener(_onPins);
    _debounce?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Everything listed, commands first: what ↑↓ walk.
  List<PaletteChoice> get _items => [
    for (final c in _commands) PaletteCommandChoice(c.command),
    for (final n in _notes) PaletteNoteChoice(n),
  ];

  void _refresh(String query) {
    setState(() {
      _commands = _rankCommands(query);
      if (query.trim().isEmpty) _notes = widget.recentNotes.take(8).toList();
      _selected = 0;
    });
    _debounce?.cancel();
    if (query.trim().isEmpty) return;
    final token = ++_token;
    _debounce = Timer(const Duration(milliseconds: 120), () async {
      final notes = await widget.searchNotes(query);
      if (!mounted || token != _token) return;
      setState(() {
        _notes = notes.take(20).toList();
        if (_selected >= _items.length) _selected = 0;
      });
    });
  }

  void _move(int step) {
    final count = _items.length;
    if (count == 0) return;
    setState(() => _selected = (_selected + step) % count);
  }

  void _choose([int? index]) {
    final items = _items;
    final at = index ?? _selected;
    if (_chosen || at < 0 || at >= items.length) return;
    _chosen = true;
    Navigator.of(context).pop(items[at]);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        _choose();
      // Alt+P pins or unpins what is selected (#208): the footer says so.
      case LogicalKeyboardKey.keyP when HardwareKeyboard.instance.isAltPressed:
        _togglePin(_selected);
      case LogicalKeyboardKey.escape:
        if (_chosen) break;
        _chosen = true;
        Navigator.of(context).pop();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _items;
    final pinned = _pinnedShown;
    final pin = widget.onTogglePin;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    var index = 0;
    Widget row(Widget child) {
      final at = index++;
      return _PaletteRow(
        key: Key('palette-item-$at'),
        selected: at == _selected,
        onTap: () => _choose(at),
        child: child,
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CommandPalette.width,
              maxHeight: 480,
            ),
            child: Material(
              key: const Key('command-palette'),
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              color: scheme.surfaceContainerHigh,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Focus(
                    onKeyEvent: _onKey,
                    child: TextField(
                      key: const Key('palette-field'),
                      controller: _query,
                      autofocus: true,
                      onChanged: _refresh,
                      onSubmitted: (_) => _choose(),
                      decoration: InputDecoration(
                        hintText: AppStrings.paletteHint,
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AppStrings.paletteNoResults,
                              style: muted,
                            ),
                          )
                        : ListView(
                            controller: _scroll,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            children: [
                              if (pinned > 0)
                                _Heading(AppStrings.palettePinned),
                              for (final command in _commands.take(pinned))
                                row(_CommandLine(command: command, pin: pin)),
                              if (_commands.length > pinned &&
                                  (pinned > 0 || _notes.isNotEmpty))
                                _Heading(AppStrings.paletteCommands),
                              for (final command in _commands.skip(pinned))
                                row(_CommandLine(command: command, pin: pin)),
                              if (_commands.isNotEmpty && _notes.isNotEmpty)
                                _Heading(AppStrings.paletteNotes),
                              for (final path in _notes)
                                row(_NoteLine(path: path)),
                            ],
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      widget.onTogglePin == null
                          ? AppStrings.paletteFooter
                          : '${AppStrings.paletteFooter} · '
                                '${AppStrings.palettePinFooter}',
                      key: const Key('palette-footer'),
                      style: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _Heading extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

final class _PaletteRow extends StatelessWidget {
  const new({
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

final class _CommandLine extends StatelessWidget {
  const new({required this.command, this.pin});

  final PaletteCommand command;

  /// Pins or unpins this row's command (#208); null leaves the pin out.
  final void Function(AppCommand command)? pin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final binding = command.binding;
    return Row(
      children: [
        Expanded(
          child: Text(
            command.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (binding != null)
          Text(
            describeActivator(binding),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        if (pin case final pin?) ...[
          const SizedBox(width: 6),
          _PinButton(command: command.command, onPressed: pin),
        ],
      ],
    );
  }
}

final class _NoteLine extends StatelessWidget {
  const new({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = p.posix.basename(path);
    final folder = p.posix.dirname(path);
    return Row(
      children: [
        Icon(
          Icons.description_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            isMarkdownNote(name) ? name.substring(0, name.length - 3) : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (folder != '.') ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The pin on a command's row: filled while it is pinned.
final class _PinButton extends StatelessWidget {
  const new({required this.command, required this.onPressed});

  final AppCommand command;
  final void Function(AppCommand command) onPressed;

  @override
  Widget build(BuildContext context) {
    final pinned = PinnedCommands.isPinned(command);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: Key('palette-pin-${command.name}'),
      tooltip: pinned ? AppStrings.paletteUnpin : AppStrings.palettePin,
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      color: pinned ? scheme.primary : scheme.onSurfaceVariant,
      icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
      onPressed: () => onPressed(command),
    );
  }
}
