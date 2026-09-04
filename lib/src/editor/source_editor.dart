import 'package:flutter/material.dart';

/// The source editor surface: a borderless, monospace, scrolling text field
/// over a plain-text buffer.
///
/// The edit model is the [TextEditingController] (plain text); highlighting
/// (T-M2-02) is layered over this later and never changes that model.
final class SourceEditor extends StatelessWidget {
  /// Creates the editor bound to [controller].
  const SourceEditor({
    required this.controller,
    super.key,
    this.focusNode,
    this.onChanged,
  });

  /// The plain-text buffer the editor reads and writes.
  final TextEditingController controller;

  /// Optional focus node (the owner uses it to save on focus loss).
  final FocusNode? focusNode;

  /// Fires with the new buffer text after every user edit.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      maxLines: null,
      expands: true,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.6,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(12),
      ),
    );
  }
}
