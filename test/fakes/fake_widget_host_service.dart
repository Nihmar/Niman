import 'package:niman/src/widget/widget_host.dart';

/// An in-memory [WidgetHostService]: the test plays the launcher.
final class FakeWidgetHostService implements WidgetHostService {
  /// The placed todo widget ids the host reports.
  List<int> todoIds = [];

  @override
  Future<List<int>> todoWidgetIds() async => List.of(todoIds);

  @override
  Future<void> dispose() async {}
}
