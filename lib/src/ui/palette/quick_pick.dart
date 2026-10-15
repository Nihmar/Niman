/// A choice among many by typing (#712): the command palette's panel for
/// one list — a field that filters, the arrows and `Enter`, `Esc` to give
/// up. What a desktop picks a template with, instead of a dialog of rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/palette/palette_reveal.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks for one of [items], each shown as its label; null when given up.
Future<T?> showQuickPick<T>(
  BuildContext context, {
  required String hint,
  required List<(String label, T value)> items,
  Key Function(T value)? itemKey,
  Key? key,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black26,
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (context, _, _) =>
      _QuickPick<T>(key: key, hint: hint, items: items, itemKey: itemKey),
);

final class _QuickPick<T> extends StatefulWidget {
  const new({required this.hint, required this.items, this.itemKey, super.key});

  final String hint;
  final List<(String, T)> items;
  final Key Function(T value)? itemKey;

  @override
  State<_QuickPick<T>> createState() => _QuickPickState<T>();
}

final class _QuickPickState<T> extends State<_QuickPick<T>> {
  final TextEditingController _query = TextEditingController();
  late List<(String, T)> _shown = widget.items;
  int _selected = 0;
  final ScrollController _scroll = ScrollController();

  /// The selected row's, to bring it into view when the arrows move it.
  final GlobalKey _selectedRow = GlobalKey();

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Every item whose label holds each word typed, in the list's order.
  void _filter(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    setState(() {
      _shown = [
        for (final item in widget.items)
          if (words.every(item.$1.toLowerCase().contains)) item,
      ];
      _selected = 0;
    });
    // The list is shorter, or another: back to its top, where row 0 is.
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.minScrollExtent);
  }

  void _choose([int? at]) {
    final index = at ?? _selected;
    if (index >= _shown.length) return;
    Navigator.pop(context, _shown[index].$2);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _shown.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _selected = (_selected + 1) % _shown.length);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _selected = (_selected - 1 + _shown.length) % _shown.length,
      );
    } else {
      return KeyEventResult.ignored;
    }
    revealPaletteRow(
      _scroll,
      _selectedRow,
      first: _selected == 0,
      last: _selected == _shown.length - 1,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                        key: const Key('quick-pick-field'),
                        controller: _query,
                        autofocus: true,
                        onChanged: _filter,
                        onSubmitted: (_) => _choose(),
                        decoration: InputDecoration(
                          hintText: widget.hint,
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
                    child: _shown.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AppStrings.paletteNoResults,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _shown.length,
                            itemBuilder: (context, at) => KeyedSubtree(
                              key: at == _selected ? _selectedRow : null,
                              child: ListTile(
                                key:
                                    widget.itemKey?.call(_shown[at].$2) ??
                                    Key('quick-pick-$at'),
                                dense: true,
                                selected: at == _selected,
                                selectedTileColor: scheme.secondaryContainer,
                                title: Text(_shown[at].$1),
                                onTap: () => _choose(at),
                              ),
                            ),
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
