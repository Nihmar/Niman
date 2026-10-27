import 'dart:collection';

/// The paths a drag carries, read from [_source] when something first looks
/// at them — a drag starting asks how many there are — and not when the row
/// that can be dragged is built (#1234).
///
/// With `Shift`+click marking a whole folder (10^5 to 10^6 paths), a frame
/// builds some forty marked rows, each of which can be dragged: copying the
/// marks for every one of them was forty copies of a million paths a frame.
/// A row now holds this instead, which copies once, for the drag that
/// happens.
final class LazyDragPaths extends ListBase<String> {
  /// Paths that [_source] lists when first asked.
  new(this._source);

  final List<String> Function() _source;

  List<String>? _paths;

  /// Whether the paths were read: false until a drag, a drop or the
  /// feedback looks at them.
  bool get isResolved => _paths != null;

  List<String> get _resolved => _paths ??= List<String>.unmodifiable(_source());

  @override
  int get length => _resolved.length;

  @override
  set length(int newLength) => throw UnsupportedError('a drag is read only');

  @override
  String operator [](int index) => _resolved[index];

  @override
  void operator []=(int index, String value) =>
      throw UnsupportedError('a drag is read only');
}
