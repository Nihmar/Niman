/// How a diagram writes a value beside what it measures (#530).
library;

/// [value] as a label writes it: two decimals at most, none when whole.
String diagramValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
