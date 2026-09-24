/// The home-screen widgets' side of the shell (issue #100, split out of
/// `shell.dart`): pushing the pinned notes and the todo snapshot out to
/// whatever the launcher has placed, and bringing a tap on one of them
/// back into the app.
///
/// It owns what that takes — the target subscription, the theme listener,
/// and the target pended across a library switch — so the shell starts
/// it, disposes it, and otherwise only answers the questions it asks.
library;

import 'dart:async';

import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_pin.dart';
import 'package:niman/src/widget/widget_placement.dart';
import 'package:niman/src/widget/widget_refresh.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

const _log = AppLogger(name: 'widgets');

/// Keeps the home-screen widgets of the open library in step, and opens
/// what a tap on one of them points at.
final class ShellHomeWidgets {
  /// Creates the flow; the services outlive the shell, the callbacks read
  /// and drive the shell's live state.
  new({
    required this.controller,
    required this.targets,
    required this.updater,
    required this.host,
    required this.todoSnapshot,
    required this.openTodo,
    required this.openNote,
    required this.mounted,
  });

  /// The open library's session (and the one a target switches away from).
  final LibrarySession controller;

  /// Taps on a placed widget, at launch and while running.
  final WidgetTargetService targets;

  /// Writes a widget's payload.
  final WidgetUpdater updater;

  /// Answers which widgets are actually placed.
  final WidgetHostService host;

  /// The todo list as it stands, or null while no library is open.
  final TodoSnapshot? Function() todoSnapshot;

  /// Shows the todo list, wherever the layout keeps it.
  final void Function() openTodo;

  /// Opens a note by library-relative path, at an anchor when given.
  final void Function(String path, String? anchor) openNote;

  /// Whether the shell is still on screen: a push after it went is a
  /// no-op, and a target it can no longer open belongs to its successor.
  final bool Function() mounted;

  /// The target a library switch is carrying.
  ///
  /// Static because the switch is what tears this flow down: the shell
  /// the target came from is disposed mid-way and the shell the switch
  /// opens picks the target up from here, in [applyLaunchTarget].
  static WidgetTarget? _pending;

  StreamSubscription<WidgetTarget>? _taps;

  /// Starts listening: widget taps, and the theme the payloads wear.
  void start() {
    _taps = targets.targets.listen((target) => unawaited(applyTarget(target)));
    AppThemes.revision.addListener(pushAll);
  }

  /// Stops listening. The pended target is deliberately left alone — it
  /// belongs to the shell this one is making way for.
  Future<void> dispose() async {
    AppThemes.revision.removeListener(pushAll);
    await _taps?.cancel();
  }

  /// Pushes the pinned notes to the note widgets reading this library
  /// (issue 6). The shell calls it on every session event: a note op
  /// bumps the revision.
  void pushNotes() {
    if (!mounted()) return;
    unawaited(
      refreshNoteWidgets(
        session: controller,
        updater: updater,
        host: host,
        pinStore: const PlatformWidgetPinStore(),
        placement: const PlatformWidgetPlacementStore(),
      ),
    );
  }

  /// Pushes the latest todo snapshot to the todo widgets reading this
  /// library (issue 6). The shell calls it on every todo notification:
  /// every mutation and the initial open notify.
  void pushTodos() {
    unawaited(
      refreshTodoWidgets(
        session: controller,
        snapshot: todoSnapshot(),
        updater: updater,
        host: host,
        placement: const PlatformWidgetPlacementStore(),
      ),
    );
  }

  /// Pushes both kinds: what a theme change (brightness or palette) asks
  /// for, since the payloads wear the resolved colors and so follow the
  /// app rather than the system night mode. Also what coming back from
  /// the background asks for — a widget placed while the app was away has
  /// no other trigger, the placement happening in the launcher with no
  /// Dart engine to hear about it. Both pushes are cheap no-ops when
  /// nothing is placed.
  void pushAll() {
    pushNotes();
    pushTodos();
  }

  /// A tap on a widget that started the app (issue 6, cold start), or the
  /// target a library switch handed over.
  ///
  /// Asked for after the shell mounts rather than at app start: the
  /// target needs an open library, so a first run that has to pick one
  /// still runs the target after. A target pended across a switch is
  /// dropped when that open failed, so a dead target never haunts the
  /// next mount.
  Future<void> applyLaunchTarget() async {
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      final current = controller.root;
      if (current != null &&
          p.normalize(pending.libraryPath) == p.normalize(current)) {
        _open(pending);
      } else {
        _log.debug('dropping widget target for a library that did not open');
      }
      return;
    }
    final target = await targets.consumeLaunchTarget();
    if (target == null) return;
    await applyTarget(target);
  }

  /// Opens [target]'s tab or note, switching libraries first when the
  /// widget points elsewhere (a widget never assumes the last-opened
  /// library).
  Future<void> applyTarget(WidgetTarget target) async {
    if (!mounted()) return;
    _log.debug(
      'target: ${target.kind.name} lib=${target.libraryPath} '
      'note=${target.notePath}',
    );
    final current = controller.root;
    if (current == null ||
        p.normalize(target.libraryPath) != p.normalize(current)) {
      // Another library. A slow switch tears the shell down mid-way, so
      // the navigation waits for the new shell — but a fast one completes
      // before any frame lands, and this shell survives. `mounted` tells
      // the two apart: a replacing frame would have disposed that state
      // already, so a still-mounted shell owns the navigation.
      _pending = target;
      await controller.switchTo(target.libraryPath);
      if (!mounted()) return;
      _pending = null;
      final now = controller.root;
      // A failed open lands on the home screen with the error instead —
      // the target dies with it rather than haunting the next mount.
      if (now != null && p.normalize(target.libraryPath) == p.normalize(now)) {
        _open(target);
      }
      return;
    }
    _open(target);
  }

  /// Runs [target]'s in-app open on the already-open library: the same
  /// tab/note the equivalent in-app control opens.
  void _open(WidgetTarget target) {
    if (!mounted()) return;
    switch (target.kind) {
      case WidgetTargetKind.todo:
        openTodo();
      case WidgetTargetKind.note:
        final note = target.notePath;
        if (note != null) openNote(note, target.anchor);
    }
  }
}
