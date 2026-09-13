import 'package:niman/src/widget/widget_placement.dart';

/// An in-memory [WidgetPlacementStore]: the test plays the config
/// activity.
final class FakeWidgetPlacementStore implements WidgetPlacementStore {
  /// Pending todo configs by widget id, cleared once consumed.
  final Map<int, ({String library})> todoConfigs = {};

  /// Pending note configs by widget id, cleared once consumed.
  final Map<int, ({String library, String note})> noteConfigs = {};

  @override
  Future<({String library})?> consumeTodoConfig(int androidWidgetId) async {
    return todoConfigs.remove(androidWidgetId);
  }

  @override
  Future<({String library, String note})?> consumeNoteConfig(
    int androidWidgetId,
  ) async {
    return noteConfigs.remove(androidWidgetId);
  }
}
