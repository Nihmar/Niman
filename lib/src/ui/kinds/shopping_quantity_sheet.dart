/// The shopping list's quantity picker: a stepper with quick counts,
/// over the item's pill or the add row's chip.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/shopping_parser.dart';
import 'package:niman/src/ui/strings.dart';

/// The counts the sheet offers in one tap, beside the stepper.
const List<int> _presets = [1, 2, 3, 5, 10];

/// Asks for a quantity, starting at [quantity].
///
/// Answers the picked quantity, or null when the sheet was dismissed
/// (`×` and Cancel are the same answer: what was there stays).
Future<int?> showShoppingQuantitySheet(
  BuildContext context, {
  required int quantity,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => _QuantitySheet(quantity: quantity),
  );
}

final class _QuantitySheet extends StatefulWidget {
  const new({required this.quantity});

  /// The quantity the sheet opens on.
  final int quantity;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

final class _QuantitySheetState extends State<_QuantitySheet> {
  late int _quantity = widget.quantity.clamp(1, shoppingQuantityMax);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.shoppingQuantityLabel,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StepButton(
                  key: const Key('quantity-minus'),
                  icon: Icons.remove,
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Expanded(
                  child: Text(
                    '$_quantity',
                    key: const Key('quantity-value'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StepButton(
                  key: const Key('quantity-plus'),
                  icon: Icons.add,
                  onPressed: _quantity < shoppingQuantityMax
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final preset in _presets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _PresetButton(
                        key: Key('quantity-preset-$preset'),
                        value: preset,
                        selected: preset == _quantity,
                        onPressed: () => setState(() => _quantity = preset),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('quantity-ok'),
                onPressed: () => Navigator.pop(context, _quantity),
                child: Text(AppStrings.actionOk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One round stepper button.
final class _StepButton extends StatelessWidget {
  const new({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      iconSize: 22,
      constraints: const BoxConstraints.tightFor(width: 52, height: 52),
    );
  }
}

/// One quick count.
final class _PresetButton extends StatelessWidget {
  const new({
    required this.value,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final int value;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        selected ? theme.colorScheme.primary : null,
      ),
      foregroundColor: WidgetStatePropertyAll(
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      ),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? BorderSide.none
              : BorderSide(color: theme.colorScheme.outline),
        ),
      ),
    );
    return TextButton(
      style: style,
      onPressed: onPressed,
      child: Text('$value'),
    );
  }
}
