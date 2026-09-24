import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/tray_menu_thread.dart';

/// A worker thread the way Windows treats one that tracks a tray menu: a
/// message queue nothing reads unless [dispatchOne] is called, and a menu
/// that "appears and then immediately disappears" when the thread starts it
/// still owing the task switch of the last one (`TrackPopupMenu` remarks).
final class _FakeThread implements TrayMenuThread {
  new({this.owner = 0x100});

  /// The handle [createOwner] hands out; 0 declines.
  final int owner;

  /// The messages waiting, each as `message@window`.
  final List<String> queue = [];

  /// Every call, in order.
  final List<String> calls = [];

  /// What the next [track] returns when the menu stays up.
  int choice = 0;

  /// Whether the next menu is dismissed by a click on another window,
  /// which leaves a deactivation for the owner's thread to handle.
  bool clickElsewhere = false;

  final Set<int> _live = {};

  @override
  int createOwner() {
    calls.add('create');
    if (owner != 0) _live.add(owner);
    return owner;
  }

  @override
  int lastError() => 0;

  @override
  bool setForeground(int owner) {
    calls.add('foreground');
    return true;
  }

  @override
  int track(int menu, int x, int y, int owner) {
    if (queue.isNotEmpty) {
      calls.add('track: closed at once');
      return 0;
    }
    calls.add('track');
    if (clickElsewhere) {
      queue.add('deactivate@$owner');
      clickElsewhere = false;
      return 0;
    }
    return choice;
  }

  @override
  void postNull(int owner) {
    calls.add('post null');
    queue.add('null@$owner');
  }

  @override
  bool dispatchOne() {
    if (queue.isEmpty) return false;
    final message = queue.removeAt(0);
    final window = int.parse(message.split('@').last);
    calls.add(
      'dispatch ${message.split('@').first}'
      '${_live.contains(window) ? '' : ' (window gone)'}',
    );
    return true;
  }

  @override
  void destroy(int owner) {
    calls.add('destroy');
    _live.remove(owner);
  }
}

void main() {
  group('trackTrayMenu', () {
    test('a menu dismissed by a click elsewhere leaves the next one up', () {
      final thread = _FakeThread()..clickElsewhere = true;
      trackTrayMenu(thread, 1, 10, 20);
      thread.calls.clear();

      final next = trackTrayMenu(thread, 1, 10, 20);

      expect(thread.calls, contains('track'));
      expect(thread.calls, isNot(contains('track: closed at once')));
      expect(next.chosen, 0);
    });

    test('the posted WM_NULL is retrieved while its owner is still there', () {
      final thread = _FakeThread()..choice = 7;

      final result = trackTrayMenu(thread, 1, 10, 20);

      expect(result.chosen, 7);
      expect(thread.calls, [
        'create',
        'foreground',
        'track',
        'post null',
        'dispatch null',
        'destroy',
      ]);
    });

    test('what a dismissal left is handled before the owner goes', () {
      final thread = _FakeThread()..clickElsewhere = true;

      trackTrayMenu(thread, 1, 10, 20);

      expect(thread.calls.sublist(thread.calls.indexOf('track')), [
        'track',
        'post null',
        'dispatch deactivate',
        'dispatch null',
        'destroy',
      ]);
      expect(thread.queue, isEmpty);
    });

    test('the thread goes back with nothing waiting in its queue', () {
      final thread = _FakeThread()..choice = 3;

      trackTrayMenu(thread, 1, 10, 20);

      expect(thread.queue, isEmpty);
    });

    test('no owner window: no menu, and the error in the report', () {
      final thread = _FakeThread(owner: 0);

      final result = trackTrayMenu(thread, 1, 10, 20);

      expect(result.chosen, 0);
      expect(result.report, startsWith('no owner window'));
      expect(thread.calls, ['create']);
    });

    test('the report carries the choice and how much the thread handled', () {
      final thread = _FakeThread()..choice = 9;

      final result = trackTrayMenu(thread, 1, 10, 20, theme: 'mode 2');

      expect(
        result.report,
        'at 10,20, theme mode 2, foreground true, result 9, error 0, '
        'handled 1',
      );
    });
  });
}
