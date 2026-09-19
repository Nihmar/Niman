/// Recording a new combination for a command (#159).
///
/// While it is open the dialog takes every key — Esc and Tab too, which
/// are keys a person may well want — so the way out is its Cancel, or
/// Esc held down for the hand that stays on the keyboard. A key
/// on its own is refused unless it is a function key: a plain letter is
/// for typing, and taking it would break every text field.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks for [command]'s new keys; resolves to them, or null on Cancel.
Future<SingleActivator?> showKeyCaptureDialog(
  BuildContext context,
  AppCommand command,
) async {
  AppKeyMap.capturing = true;
  try {
    return await showDialog<SingleActivator>(
      context: context,
      // Only Cancel closes it: Esc is one of the keys it records.
      barrierDismissible: false,
      builder: (context) => KeyCaptureDialog(command: command),
    );
  } finally {
    AppKeyMap.capturing = false;
  }
}

/// The dialog itself.
final class KeyCaptureDialog extends StatefulWidget {
  /// Records keys for [command].
  const new({required this.command, super.key});

  /// The command being given keys.
  final AppCommand command;

  @override
  State<KeyCaptureDialog> createState() => _KeyCaptureDialogState();
}

final class _KeyCaptureDialogState extends State<KeyCaptureDialog> {
  final FocusNode _focus = FocusNode(debugLabel: 'key capture');
  SingleActivator? _keys;
  bool _needsModifier = false;

  static final Set<LogicalKeyboardKey> _modifiers = {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.meta,
  };

  /// F1 to F24: the keys that may stand alone.
  static bool _isFunctionKey(LogicalKeyboardKey key) =>
      key.keyId >= LogicalKeyboardKey.f1.keyId &&
      key.keyId <= LogicalKeyboardKey.f24.keyId;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Esc held down is the keyboard's way out: a tap records Esc, the
    // repeat that holding it starts cancels.
    if (event is KeyRepeatEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    // Everything is taken while recording; only a key-down records.
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final key = event.logicalKey;
    if (_modifiers.contains(key)) return KeyEventResult.handled;
    final keys = HardwareKeyboard.instance;
    final withModifier =
        keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed;
    if (!withModifier && !_isFunctionKey(key)) {
      setState(() {
        _keys = null;
        _needsModifier = true;
      });
      return KeyEventResult.handled;
    }
    setState(() {
      _needsModifier = false;
      _keys = SingleActivator(
        key,
        control: keys.isControlPressed,
        shift: keys.isShiftPressed,
        alt: keys.isAltPressed,
        meta: keys.isMetaPressed,
      );
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = _keys;
    return AlertDialog(
      key: const Key('key-capture'),
      title: Text(
        AppStrings.shortcutCaptureTitle(appCommandLabel(widget.command)),
      ),
      content: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.shortcutCapturePrompt,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              key: const Key('key-capture-keys'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text(
                keys == null ? '…' : describeActivator(keys),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            if (_needsModifier) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.shortcutCaptureNeedsModifier,
                key: const Key('key-capture-needs-modifier'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('key-capture-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('key-capture-save'),
          onPressed: keys == null
              ? null
              : () => Navigator.of(context).pop(keys),
          child: Text(AppStrings.actionSave),
        ),
      ],
    );
  }
}
