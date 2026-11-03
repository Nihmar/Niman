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
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/palette/palette_action_line.dart';
import 'package:niman/src/ui/palette/palette_choice.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/palette/palette_command_line.dart';
import 'package:niman/src/ui/palette/palette_feature_line.dart';
import 'package:niman/src/ui/palette/palette_heading.dart';
import 'package:niman/src/ui/palette/palette_match.dart';
import 'package:niman/src/ui/palette/palette_note_line.dart';
import 'package:niman/src/ui/palette/palette_off_command.dart';
import 'package:niman/src/ui/palette/palette_reveal.dart';
import 'package:niman/src/ui/palette/palette_row.dart';
import 'package:niman/src/ui/palette/palette_setting.dart';
import 'package:niman/src/ui/palette/palette_setting_line.dart';
import 'package:niman/src/ui/palette/pinned_commands.dart';
import 'package:niman/src/ui/strings.dart';

/// Shows the palette and resolves to what was picked, or null.
///
/// [commands] are the ones that can run here and now; [notesOnly] is
/// Go to note's palette, with the commands left out. [onTogglePin] pins
/// and unpins a command (#208); null leaves the pins out. [offCommands] are
/// the commands whose feature is off: never listed, they only let the
/// palette say so when a query matches nothing else of the commands.
Future<PaletteChoice?> showCommandPalette(
  BuildContext context, {
  required List<PaletteCommand> commands,
  required Future<List<String>> Function(String query) searchNotes,
  List<AppCommand> recentCommands = const [],
  List<String> recentNotes = const [],
  List<PaletteSetting> settings = const [],
  List<PaletteOffCommand> offCommands = const [],
  Future<List<HomeAction>> Function()? homeActions,
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
      offCommands: notesOnly ? const [] : offCommands,
      searchNotes: searchNotes,
      recentCommands: recentCommands,
      recentNotes: recentNotes,
      settings: notesOnly ? const [] : settings,
      homeActions: notesOnly ? null : homeActions,
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
    this.settings = const [],
    this.offCommands = const [],
    this.homeActions,
    this.onTogglePin,
    super.key,
  });

  /// The commands on offer.
  final List<PaletteCommand> commands;

  /// The commands that would be on offer but for their feature being off
  /// (#1109).
  final List<PaletteOffCommand> offCommands;

  /// Finds notes by name.
  final Future<List<String>> Function(String query) searchNotes;

  /// Commands used lately, most recent first.
  final List<AppCommand> recentCommands;

  /// Notes opened lately, most recent first.
  final List<String> recentNotes;

  /// The settings rows the search can answer with (#229): after the
  /// commands and the notes, because a setting is the rarest of the
  /// three and the slowest to want.
  final List<PaletteSetting> settings;

  /// The Home's actions (#535), read once the palette is up so it never
  /// waits on the file; null for none.
  final Future<List<HomeAction>> Function()? homeActions;

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

  /// The selected row's, to bring it into view when the arrows move it.
  final GlobalKey _selectedRow = GlobalKey();
  List<PaletteCommand> _commands = const [];
  List<String> _notes = const [];
  List<PaletteSetting> _settings = const [];
  List<HomeAction> _allActions = const [];
  List<HomeAction> _actions = const [];

  /// The feature the typed text found commands of, none of them on offer
  /// (#1109), or null.
  LibraryFeature? _offFeature;
  int _selected = 0;
  int _token = 0;
  Timer? _debounce;

  /// Set once something was picked: Enter can arrive both as a key and
  /// as the field's submit, and the second must not pop the screen below.
  bool _chosen = false;

  /// True from a keystroke until the note search for the text then in the
  /// field has landed (#1034): until then the note rows are the recent
  /// notes or the previous keystroke's hits, not what was typed for.
  bool _pending = false;

  /// Enter arrived on a note row while [_pending]: the choice waits for
  /// the fresh list and is made from it, instead of opening a stale row.
  bool _chooseWhenFresh = false;

  @override
  void initState() {
    super.initState();
    _commands = _rankCommands('');
    _notes = widget.recentNotes.take(8).toList();
    // A pin from a row re-ranks the list under it (#208): the row moves
    // to the pinned head, or leaves it, without reopening the palette.
    PinnedCommands.current.addListener(_onPins);
    unawaited(_loadActions());
  }

  Future<void> _loadActions() async {
    final load = widget.homeActions;
    if (load == null) return;
    final actions = await load();
    if (!mounted) return;
    setState(() {
      _allActions = actions;
      _actions = _rankActions(_query.text);
    });
  }

  /// An action's name in the palette: `Home: Meeting…`, like a command.
  static String _actionName(HomeAction action) =>
      '${AppStrings.tabHome}: ${homeActionLabel(action)}'
      '${action.asks ? '…' : ''}';

  /// The actions [query] finds; nothing with nothing typed, so the
  /// palette still opens on what was used.
  List<HomeAction> _rankActions(String query) {
    if (query.trim().isEmpty) return const [];
    return paletteRank(
      _allActions,
      query,
      name: _actionName,
      id: (a) => a.id,
    ).take(6).toList();
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

  /// The feature [query] found commands of when none is on offer: the
  /// quiet line's, so a list with no command says why (#1109).
  LibraryFeature? _offFeatureFor(String query) {
    if (query.trim().isEmpty || _commands.isNotEmpty) return null;
    return paletteRank(
      widget.offCommands,
      query,
      name: (o) => o.command.name,
      id: (o) => o.command.command,
    ).firstOrNull?.feature;
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

  /// Everything listed, commands first, settings last: what ↑↓ walk.
  List<PaletteChoice> get _items => [
    for (final c in _commands) PaletteCommandChoice(c.command),
    for (final a in _actions) PaletteActionChoice(a),
    for (final n in _notes) PaletteNoteChoice(n),
    for (final s in _settings) PaletteSettingChoice(s),
  ];

  /// The settings rows [query] finds; nothing with nothing typed, since
  /// the palette opens on what was used, and a setting never was.
  List<PaletteSetting> _rankSettings(String query) {
    if (query.trim().isEmpty) return const [];
    return paletteRank(
      widget.settings,
      query,
      name: (s) => '${s.area} ${s.title}',
      id: (s) => s.title,
    ).take(5).toList();
  }

  void _refresh(String query) {
    // A new text voids the search in flight and the Enter queued on it.
    _chooseWhenFresh = false;
    setState(() {
      _settings = _rankSettings(query);
      _commands = _rankCommands(query);
      _offFeature = _offFeatureFor(query);
      _actions = _rankActions(query);
      if (query.trim().isEmpty) _notes = widget.recentNotes.take(8).toList();
      _selected = 0;
    });
    // Another list, or a shorter one: back to its top, where row 0 is.
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.minScrollExtent);
    _debounce?.cancel();
    final token = ++_token;
    if (query.trim().isEmpty) {
      _pending = false;
      return;
    }
    _pending = true;
    _debounce = Timer(const Duration(milliseconds: 120), () async {
      List<String> notes;
      try {
        notes = await widget.searchNotes(query);
      } on Object {
        notes = const [];
      }
      if (!mounted || token != _token) return;
      final choose = _chooseWhenFresh;
      setState(() {
        _pending = false;
        _chooseWhenFresh = false;
        _notes = notes.take(20).toList();
        if (_selected >= _items.length) _selected = 0;
      });
      if (choose) _choose();
    });
  }

  /// Whether the row at [index] is a note row still showing the notes of
  /// an earlier text (#1034). Commands, actions and settings are ranked
  /// on the spot, so they are never stale.
  bool _isStale(int index) =>
      _pending && index >= 0 && _items[index] is PaletteNoteChoice;

  /// Selects the row at [index] (the pointer moved onto it).
  void _select(int index) {
    if (index == _selected || index < 0 || index >= _items.length) return;
    setState(() => _selected = index);
  }

  void _move(int step) {
    final count = _items.length;
    if (count == 0) return;
    setState(() => _selected = (_selected + step) % count);
    revealPaletteRow(
      _scroll,
      _selectedRow,
      first: _selected == 0,
      last: _selected == count - 1,
    );
  }

  void _choose([int? index]) {
    final items = _items;
    final at = index ?? _selected;
    if (_chosen || at < 0 || at >= items.length) return;
    // Enter on a stale note row waits for the search for the typed text
    // and chooses from its list (#1034); a tap names the row it hit.
    if (index == null && _isStale(at)) {
      _chooseWhenFresh = true;
      return;
    }
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
    // The keys shown depend on there being keys to press (#230), and a
    // keyboard can arrive while the palette is open.
    return ListenableBuilder(
      listenable: KeyboardPresence.shared,
      builder: (context, _) => _panelWithKeys(context),
    );
  }

  Widget _panelWithKeys(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _items;
    final pinned = _pinnedShown;
    final pin = widget.onTogglePin;
    final keys = KeyboardPresence.shared.attached;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    var index = 0;
    Widget row(Widget child) {
      final at = index++;
      return PaletteRow(
        key: Key('palette-item-$at'),
        selected: at == _selected,
        anchor: at == _selected ? _selectedRow : null,
        // The pointer moves the selection with it, as every palette
        // does: the row under the hand is the row ↵ runs and Alt+P pins
        // (0.0.8 test round — pinning acted on a row elsewhere).
        onHover: () => _select(at),
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
                  ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Focus(
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
                                PaletteHeading(AppStrings.palettePinned),
                              for (final command in _commands.take(pinned))
                                row(
                                  PaletteCommandLine(
                                    command: command,
                                    pin: pin,
                                    keys: keys,
                                  ),
                                ),
                              if (_commands.length > pinned &&
                                  (pinned > 0 || _notes.isNotEmpty))
                                PaletteHeading(AppStrings.paletteCommands),
                              for (final command in _commands.skip(pinned))
                                row(
                                  PaletteCommandLine(
                                    command: command,
                                    pin: pin,
                                    keys: keys,
                                  ),
                                ),
                              if (_actions.isNotEmpty)
                                PaletteHeading(AppStrings.tabHome),
                              for (final action in _actions)
                                row(
                                  PaletteActionLine(
                                    action: action,
                                    name: _actionName(action),
                                  ),
                                ),
                              if ((_commands.isNotEmpty ||
                                      _actions.isNotEmpty) &&
                                  _notes.isNotEmpty)
                                PaletteHeading(AppStrings.paletteNotes),
                              for (final path in _notes)
                                row(
                                  // Dimmed while the search for the typed
                                  // text is out: they are not its hits yet.
                                  Opacity(
                                    opacity: _pending ? 0.5 : 1,
                                    child: PaletteNoteLine(path: path),
                                  ),
                                ),
                              if (_settings.isNotEmpty)
                                PaletteHeading(AppStrings.tabSettings),
                              for (final setting in _settings)
                                row(PaletteSettingLine(setting: setting)),
                            ],
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Without a keyboard the arrows and alt+P are
                          // nothing to say (#230): the pin is a tap.
                          !keys
                              ? AppStrings.paletteFooterTouch
                              : widget.onTogglePin == null
                              ? AppStrings.paletteFooter
                              : '${AppStrings.paletteFooter} · '
                                    '${AppStrings.palettePinFooter}',
                          key: const Key('palette-footer'),
                          style: muted,
                        ),
                        if (_offFeature case final feature?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: PaletteFeatureLine(
                              feature: feature,
                              onOpen: () {
                                if (_chosen) return;
                                _chosen = true;
                                Navigator.of(context)
                                    .pop(const PaletteFeaturesChoice());
                              },
                            ),
                          ),
                      ],
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
