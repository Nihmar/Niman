import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/ui/dictionary_panel.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_session.dart';
import 'package:niman/src/ui/dictionary_panel/panel_placement.dart';

/// The desktop's panel (screen C): an entry of the window's overlay, under
/// the selection, that closes on Esc or a click anywhere outside it.
///
/// There is one at a time. Choosing *Look up* on another selection while it
/// is open updates it where it is ([update]): the reader keeps their place
/// and the panel its position.
final class DictionaryPopup extends ChangeNotifier {
  new _(this.session, this._installation, this._onOpenSettings);

  static DictionaryPopup? _current;

  /// The panel on screen, or null. One whose window went away without
  /// closing it (a tab closed under it) is not on screen.
  static DictionaryPopup? get current {
    final open = _current;
    if (open != null && (open._closed || !open._overlay.mounted)) {
      _current = null;
    }
    return _current;
  }

  /// Opens the panel for [session] under [anchor], the selection in the
  /// coordinates of the window; closes the one that was open.
  static DictionaryPopup open(
    BuildContext context, {
    required DictionaryLookupSession session,
    required DictionaryInstallation installation,
    required Rect anchor,
    required VoidCallback onOpenSettings,
    DictionaryAnnotate? annotate,
  }) {
    current?.close();
    final overlay = Overlay.of(context, rootOverlay: true);
    final popup = DictionaryPopup._(session, installation, onOpenSettings)
      .._overlay = overlay
      .._anchor = anchor
      .._annotate = annotate
      .._returnTo = FocusManager.instance.primaryFocus;
    popup._entry = OverlayEntry(builder: popup._build);
    overlay.insert(popup._entry);
    // The keyboard goes to the panel, for Esc: asked for once it is built,
    // since the node that was pressed to open it may hold the focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!popup._closed) popup._focus.requestFocus();
    });
    _current = popup;
    return popup;
  }

  /// The look-ups of the panel.
  final DictionaryLookupSession session;
  final DictionaryInstallation _installation;
  final VoidCallback _onOpenSettings;
  late final OverlayEntry _entry;
  late final OverlayState _overlay;
  Rect _anchor = Rect.zero;
  DictionaryAnnotate? _annotate;
  final FocusNode _focus = FocusNode(debugLabel: 'dictionary panel');
  FocusNode? _returnTo;
  bool _closed = false;

  /// Moves the panel to [anchor] and lets [annotate] be what its icon does:
  /// another selection was looked up in it.
  void update({required Rect anchor, DictionaryAnnotate? annotate}) {
    _anchor = anchor;
    _annotate = annotate;
    notifyListeners();
  }

  /// Closes the panel and gives the keyboard back to where it was.
  void close() {
    if (_closed) return;
    _closed = true;
    if (identical(_current, this)) _current = null;
    if (_overlay.mounted) _entry.remove();
    _entry.dispose();
    final back = _returnTo;
    if (back != null && back.context != null && back.canRequestFocus) {
      back.requestFocus();
    }
    _focus.dispose();
    session.dispose();
    dispose();
  }

  Widget _build(BuildContext context) => Stack(
    children: [
      // Any press outside the panel closes it, and goes on to the page
      // under it: a click on another word selects it.
      Positioned.fill(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => close(),
        ),
      ),
      ListenableBuilder(
        listenable: this,
        builder: (context, _) => CustomSingleChildLayout(
          delegate: PanelPlacement(_anchor),
          child: Focus(
            focusNode: _focus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                close();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Material(
              key: const Key('lookup-popup'),
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: DictionaryPanel(
                session: session,
                installation: _installation,
                annotate: _annotate,
                onClose: close,
                onOpenSettings: () {
                  close();
                  _onOpenSettings();
                },
                compact: true,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
