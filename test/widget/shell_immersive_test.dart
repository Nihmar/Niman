// #784: the full-screen book's notifier makes the platform call only;
// the shell is not rebuilt for it, so a book pane clearing it from its
// dispose (inside the frame's tree finalization) is no locked-tree
// setState.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_zen.dart';

import '../fakes/fake_window_controller.dart';

void main() {
  testWidgets('a book closed in full screen does not rebuild the shell', (
    tester,
  ) async {
    final window = FakeWindowController();
    final immersive = ShellImmersive(window: window, possible: () => true);
    addTearDown(immersive.dispose);
    final book = Object();
    final showBook = ValueNotifier<bool>(true);
    addTearDown(showBook.dispose);

    await tester.pumpWidget(
      _Shell(
        immersive: immersive,
        child: ValueListenableBuilder<bool>(
          valueListenable: showBook,
          builder: (context, show, _) => show
              ? _Book(owner: immersive.fullScreen, book: book)
              : const SizedBox(),
        ),
      ),
    );
    immersive.fullScreen.value = book;
    await tester.pump();
    expect(window.fullScreen, isTrue);

    // The tab closes: the pane gives the screen back from its dispose.
    showBook.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(window.fullScreen, isFalse);
  });
}

/// The shell's part: repaints on every immersive change.
class _Shell extends StatefulWidget {
  const new({required this.immersive, required this.child});

  final ShellImmersive immersive;
  final Widget child;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  @override
  void initState() {
    super.initState();
    widget.immersive.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.immersive.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: widget.child);
}

/// A book pane holding the full screen: `EpubPaneState.dispose` clears
/// the owner when the book is its own.
class _Book extends StatefulWidget {
  const new({required this.owner, required this.book});

  final ValueNotifier<Object?> owner;
  final Object book;

  @override
  State<_Book> createState() => _BookState();
}

class _BookState extends State<_Book> {
  @override
  void dispose() {
    if (widget.owner.value == widget.book) widget.owner.value = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
