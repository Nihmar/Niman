import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// A name-entry dialog; resolves to the trimmed text or null.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(title: title, initial: initial),
  );
}

/// The dialog body. Owns the [TextEditingController] so it lives as long
/// as the dialog (a disposed controller would break the exit animation
/// while the [TextField] rebuilds).
final class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

final class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(AppStrings.actionOk)),
      ],
    );
  }
}
