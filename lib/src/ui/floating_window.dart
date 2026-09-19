/// A floating window over the shell (#202): a panel with a title and a
/// close button, over whatever is on screen, which closes back to it.
///
/// The command palette is the model: Esc and a click outside dismiss it,
/// and the note, its tabs and the tree stay where they were underneath.
/// Unlike the palette the window has screens of its own to open — a
/// settings area pushes the keyboard or the toolbar screen — so it keeps
/// its own navigator, and those screens open inside the panel instead
/// of over the whole app. Esc steps back through them before it closes
/// the window.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows [builder]'s page in a floating window titled [title], and
/// resolves when the window closes.
///
/// The panel is [size] at most, centred, and never closer than a margin
/// to the window's edges. [panelKey] names the panel, for tests.
Future<void> showFloatingWindow(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  required Key panelKey,
  Size size = FloatingWindow.defaultSize,
}) {
  return Navigator.of(context).push(
    floatingWindowRoute(
      context,
      title: title,
      builder: builder,
      panelKey: panelKey,
      size: size,
    ),
  );
}

/// The route [showFloatingWindow] pushes, for a caller that has to take
/// the window down itself: one over a library's shell goes with the
/// shell when the library closes.
Route<void> floatingWindowRoute(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  required Key panelKey,
  Size size = FloatingWindow.defaultSize,
}) {
  return RawDialogRoute<void>(
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, _) => FloatingWindow(
      panelKey: panelKey,
      title: title,
      size: size,
      builder: builder,
    ),
  );
}

/// The window's panel.
final class FloatingWindow extends StatefulWidget {
  /// A panel titled [title] around [builder]'s page, [size] at most.
  const new({
    required this.title,
    required this.builder,
    this.size = defaultSize,
    this.panelKey,
    super.key,
  });

  /// The title on the panel's header.
  final String title;

  /// The first page, and the one Esc closes the window from.
  final WidgetBuilder builder;

  /// The largest the panel grows.
  final Size size;

  /// The panel's own key, for tests: the widget itself fills the screen.
  final Key? panelKey;

  /// Room for the settings' two columns, and less than a laptop screen.
  static const Size defaultSize = Size(960, 680);

  /// The least room kept between the panel and the window's edges.
  static const double margin = 24;

  @override
  State<FloatingWindow> createState() => _FloatingWindowState();
}

final class _FloatingWindowState extends State<FloatingWindow> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey();

  /// Esc: back one screen inside the window, or close it from the first.
  void _dismiss() {
    final inner = _navigator.currentState;
    if (inner != null && inner.canPop()) {
      inner.pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outer = MediaQuery.of(context);
    final width = (outer.size.width - 2 * FloatingWindow.margin).clamp(
      0.0,
      widget.size.width,
    );
    final height = (outer.size.height - 2 * FloatingWindow.margin).clamp(
      0.0,
      widget.size.height,
    );
    return Center(
      child: SizedBox(
        key: widget.panelKey,
        width: width,
        height: height,
        // A key handler, not a DismissIntent action: every page's route
        // and Scaffold carry a disabled Esc action of their own, and the
        // nearest one is the one the app's Esc asks. The key reaches this
        // node before it reaches the app's shortcuts; a menu or a dialog
        // over the window has its own focus, away from here.
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent ||
                event.logicalKey != LogicalKeyboardKey.escape) {
              return KeyEventResult.ignored;
            }
            _dismiss();
            return KeyEventResult.handled;
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: widget.title,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const Divider(height: 1),
                Expanded(child: _body(outer, Size(width, height))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The pages, laid out as if the panel were the screen: a page that
  /// reads the screen's size to choose its shape reads the panel's.
  Widget _body(MediaQueryData outer, Size panel) {
    return MediaQuery(
      data: outer.copyWith(
        size: panel,
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
      ),
      // Its own messenger, so a page's snack bar shows in the panel and
      // not on the shell dimmed behind it.
      child: ScaffoldMessenger(
        child: HeroControllerScope.none(
          child: Navigator(
            key: _navigator,
            onGenerateInitialRoutes: (_, _) => [
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  backgroundColor: Colors.transparent,
                  body: widget.builder(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const new({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('floating-window-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
