import 'package:niman/src/widget/widget_host.dart';

/// An in-memory [WidgetHostService]: the test plays the launcher.
final class FakeWidgetHostService implements WidgetHostService {
  /// The placed todo widget ids the host reports.
  List<int> todoIds = [];

  /// The placed note widget ids the host reports.
  List<int> noteIds = [];

  @override
  Future<List<int>> todoWidgetIds() async => List.of(todoIds);

  @override
  Future<List<int>> noteWidgetIds() async => List.of(noteIds);

  @override
  Future<void> dispose() async {}
}
