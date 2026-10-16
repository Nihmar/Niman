import 'package:flutter/material.dart';

/// One mounted note of a [DetailDeck]: what it draws, and how it takes
/// the keyboard.
@immutable
final class DeckSlot {
  /// A slot for the note at [id], drawing [child].
  const new({
    required this.id,
    required this.active,
    required this.child,
    this.takeFocus,
  });

  /// The note's library-relative path: the slot's identity.
  final String id;

  /// Whether the note is the one on stage.
  final bool active;

  /// The note's view.
  final Widget child;

  /// Puts the keyboard in the note's editor; null for a view with none (a
  /// picture, a PDF, a book).
  final VoidCallback? takeFocus;
}

/// The open notes of a pane, stacked: the one on stage shows, the others
/// stay mounted behind it (#23).
///
/// A hidden note is out of the way of the keyboard as well as of the eye
/// (#1074): [Offstage] children "can receive focus and have keyboard input
/// directed to them", so a tab left with the caret in it went on taking the
/// typing while another note showed. Every hidden slot is wrapped in
/// [ExcludeFocus], which also lets go of the focus a slot holds when it is
/// hidden.
///
/// The keyboard then follows the stage: when the note on stage changes and
/// the keyboard was in the note that left (or in the shell itself, on its
/// accelerator node), the note now showing takes it. A tree row, a search
/// field or another pane keeps what it had.
final class DetailDeck extends StatefulWidget {
  /// Stacks [slots], the active one showing.
  const new({
    required this.slots,
    this.paneFocused = true,
    this.shellFocus,
    super.key,
  });

  /// The notes, in the order they are mounted.
  final List<DeckSlot> slots;

  /// Whether this is the focused pane: only that one takes the keyboard
  /// from the shell.
  final bool paneFocused;

  /// The node the shell keeps the accelerators on when nothing else has the
  /// focus.
  final FocusNode? shellFocus;

  @override
  State<DetailDeck> createState() => _DetailDeckState();
}

class _DetailDeckState extends State<DetailDeck> {
  /// One node per slot, around its view: it has the focus while the
  /// keyboard is anywhere inside.
  final Map<String, FocusNode> _nodes = {};

  static String? _activeOf(List<DeckSlot> slots) {
    for (final slot in slots) {
      if (slot.active) return slot.id;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant DetailDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = _activeOf(oldWidget.slots);
    final now = _activeOf(widget.slots);
    if (now == null || now == before || !_keyboardFollows(before)) return;
    // After the frame: the hidden slot lets go of the focus as this one is
    // built, and the new note's editor may be mounted by it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final slot in widget.slots) {
        if (slot.id == now && slot.active) slot.takeFocus?.call();
      }
    });
  }

  /// Whether the keyboard was in the note that left the stage, or in the
  /// shell where no control has it.
  bool _keyboardFollows(String? before) {
    if (before != null && (_nodes[before]?.hasFocus ?? false)) return true;
    if (!widget.paneFocused) return false;
    final primary = FocusManager.instance.primaryFocus;
    return primary == null ||
        primary is FocusScopeNode ||
        primary == widget.shellFocus;
  }

  FocusNode _nodeOf(String id) =>
      _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'deck slot $id'));

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = {for (final slot in widget.slots) slot.id};
    // A slot that is gone takes its node with it, once the frame is done
    // with the focus tree it was in.
    final gone = [
      for (final id in _nodes.keys)
        if (!ids.contains(id)) id,
    ];
    if (gone.isNotEmpty) {
      final nodes = [for (final id in gone) _nodes.remove(id)!];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in nodes) {
          node.dispose();
        }
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final slot in widget.slots)
          Offstage(
            key: ValueKey('detail-note-${slot.id}'),
            offstage: !slot.active,
            child: TickerMode(
              enabled: slot.active,
              child: ExcludeFocus(
                excluding: !slot.active,
                child: Focus(
                  focusNode: _nodeOf(slot.id),
                  canRequestFocus: false,
                  skipTraversal: true,
                  child: slot.child,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
