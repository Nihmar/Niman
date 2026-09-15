import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// A one-field prompt dialog that owns its controller, so popping the
/// route never disposes a controller the exit animation still reads.
class AudioPromptDialog extends StatefulWidget {
  /// Creates the dialog; it pops with the typed text, or null on cancel.
  const new({
    required this.title,
    required this.initial,
    this.hint,
    this.confirm,
    this.singleLine = false,
    super.key,
  });

  /// The dialog title.
  final String title;

  /// The field's starting text.
  final String initial;

  /// The field's hint.
  final String? hint;

  /// The confirm label (default: Save).
  final String? confirm;

  /// Whether the field holds one line (Enter confirms).
  final bool singleLine;

  @override
  State<AudioPromptDialog> createState() => _AudioPromptDialogState();
}

class _AudioPromptDialogState extends State<AudioPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.singleLine ? 1 : null,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: widget.singleLine ? (_) => _confirm() : null,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(widget.confirm ?? AppStrings.actionSave),
        ),
      ],
    );
  }
}
