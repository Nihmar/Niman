import 'package:niman/src/widget/widget_pin.dart';

/// An in-memory [WidgetPinStore]: the test pins the note.
final class FakeWidgetPinStore implements WidgetPinStore {
  /// The pending pin, cleared once consumed.
  ({String libraryPath, String notePath})? pin;

  @override
  Future<({String libraryPath, String notePath})?> consumePin() async {
    final pending = pin;
    pin = null;
    return pending;
  }
}
