/// A tree row's name, edited where it is (#707): the desktop's rename, as
/// a file manager has it, in place of the dialog a phone keeps.
///
/// The name comes selected without its extension (`note` of `note.md`, a
/// folder's whole name). `Enter` or a click elsewhere commits, `Esc` puts
/// the name back; an empty or unchanged name changes nothing. A name that
/// cannot be used leaves the field open and says why under it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The field a renamed row shows in place of its name.
final class TreeRenameField extends StatefulWidget {
  /// Edits [name], the row's file or folder name on disk.
  const new({
    required this.name,
    required this.isDir,
    required this.onSubmit,
    required this.onCancel,
    this.style,
    super.key,
  });

  /// The name as it stands.
  final String name;

  /// Whether the row is a folder, whose whole name is selected.
  final bool isDir;

  /// Renames to the name given: null once done, or why it cannot be.
  final Future<String?> Function(String name) onSubmit;

  /// Leaves the name as it was.
  final VoidCallback onCancel;

  /// The row's own text style, so the name does not jump as it opens.
  final TextStyle? style;

  @override
  State<TreeRenameField> createState() => _TreeRenameFieldState();
}

final class _TreeRenameFieldState extends State<TreeRenameField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.name,
  )..selection = TextSelection(baseOffset: 0, extentOffset: _stemEnd);

  final FocusNode _focus = FocusNode(debugLabel: 'tree-rename');

  /// Why the name typed cannot be used; null while it can.
  String? _error;

  /// Whether the stem has been selected since the field took the focus.
  bool _stemSelected = false;

  /// Whether a rename is on its way, or the field is done.
  bool _busy = false;
  bool _done = false;

  /// Where the name's stem ends: before a file's extension, the whole of a
  /// folder's name or of a file that has none.
  int get _stemEnd {
    final name = widget.name;
    if (widget.isDir) return name.length;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? dot : name.length;
  }

  @override
  void initState() {
    super.initState();
    // A click elsewhere commits, as a file manager's field does.
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        unawaited(_commit());
      } else if (!_stemSelected) {
        // A desktop's field selects all of itself as it takes the focus:
        // the stem is selected again once it has.
        _stemSelected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _text.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _stemEnd,
          );
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      Scrollable.ensureVisible(context, alignmentPolicy: _policy);
    });
  }

  /// Scrolls only as far as it takes, whichever side the row is off.
  static const ScrollPositionAlignmentPolicy _policy =
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    if (_busy || _done) return;
    final name = _text.text.trim();
    if (name.isEmpty || name == widget.name) return _cancel();
    _busy = true;
    final error = await widget.onSubmit(name);
    if (!mounted) return;
    _busy = false;
    if (error == null) {
      _done = true;
      return;
    }
    setState(() => _error = error);
    _focus.requestFocus();
  }

  void _cancel() {
    if (_done) return;
    _done = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
    child: TextField(
      key: const Key('tree-rename-field'),
      controller: _text,
      focusNode: _focus,
      style: widget.style,
      onSubmitted: (_) => unawaited(_commit()),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        isDense: true,
        errorText: _error,
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
