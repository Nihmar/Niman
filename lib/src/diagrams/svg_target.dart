/// The [DiagramTarget] that emits an SVG document (#530).
///
/// It is the export's half of the one drawing: the same renderer walks the
/// same layout and writes `<polygon>`, `<path>`, `<line>` and `<text>`
/// instead of painting them.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_target.dart';

/// The control characters XML 1.0 does not allow, tab and line ends aside.
final RegExp _notXml = RegExp('[\x00-\x08\x0B\x0C\x0E-\x1F]');

/// Writes a diagram as an SVG string.
final class SvgDiagramTarget implements DiagramTarget {
  /// Creates a target for a drawing of [width] by [height].
  new({required this.width, required this.height, this.fontFamily}) {
    _buffer.write(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${_n(width)}" height="${_n(height)}" '
      'viewBox="0 0 ${_n(width)} ${_n(height)}">',
    );
  }

  /// The drawing's width.
  final double width;

  /// The drawing's height.
  final double height;

  /// The typeface labels are written in, or null for the reader's.
  final String? fontFamily;

  final StringBuffer _buffer = StringBuffer();

  /// Closes the document and returns it.
  String finish() {
    _buffer.write('</svg>');
    return _buffer.toString();
  }

  @override
  void polygon(
    List<Offset> points, {
    Color? fill,
    Color? stroke,
    double strokeWidth = 1,
  }) {
    if (points.length < 2) return;
    final data = points.map((p) => '${_n(p.dx)},${_n(p.dy)}').join(' ');
    _buffer
      ..write('<polygon points="$data"')
      ..write(' fill="${fill == null ? 'none' : _color(fill)}"');
    if (stroke != null) {
      _buffer
        ..write(' stroke="${_color(stroke)}"')
        ..write(' stroke-width="${_n(strokeWidth)}"')
        ..write(' stroke-linejoin="round"');
    }
    _buffer.write('/>');
  }

  @override
  void cubic(
    Offset from,
    Offset control1,
    Offset control2,
    Offset to, {
    required Color color,
    double strokeWidth = 1,
    bool dashed = false,
  }) {
    final path =
        'M ${_n(from.dx)} ${_n(from.dy)} '
        'C ${_n(control1.dx)} ${_n(control1.dy)} '
        '${_n(control2.dx)} ${_n(control2.dy)} '
        '${_n(to.dx)} ${_n(to.dy)}';
    _stroke(path, color, strokeWidth, dashed);
  }

  @override
  void line(
    Offset from,
    Offset to, {
    required Color color,
    double strokeWidth = 1,
    bool dashed = false,
  }) {
    final path = 'M ${_n(from.dx)} ${_n(from.dy)} L ${_n(to.dx)} ${_n(to.dy)}';
    _stroke(path, color, strokeWidth, dashed);
  }

  @override
  void text(
    List<String> lines,
    Rect box, {
    required Color color,
    required double fontSize,
    bool alignLeft = false,
    FontWeight weight = FontWeight.normal,
  }) {
    if (lines.isEmpty) return;
    final lineHeight = fontSize * 1.25;
    final anchor = alignLeft ? 'start' : 'middle';
    final x = alignLeft ? box.left : box.center.dx;
    final firstY =
        box.center.dy - (lines.length - 1) / 2 * lineHeight + fontSize * 0.35;
    _buffer
      ..write('<text x="${_n(x)}" y="${_n(firstY)}"')
      ..write(' text-anchor="$anchor"')
      ..write(' font-size="${_n(fontSize)}"')
      ..write(' font-weight="${weight.value}"')
      ..write(' fill="${_color(color)}"');
    if (fontFamily != null) {
      _buffer.write(' font-family="${_escape(fontFamily!)}"');
    }
    _buffer.write('>');
    for (var i = 0; i < lines.length; i++) {
      if (i == 0) {
        _buffer.write(_escape(lines[i]));
      } else {
        _buffer.write(
          '<tspan x="${_n(x)}" dy="${_n(lineHeight)}">'
          '${_escape(lines[i])}</tspan>',
        );
      }
    }
    _buffer.write('</text>');
  }

  void _stroke(String path, Color color, double width, bool dashed) {
    _buffer
      ..write('<path d="$path" fill="none"')
      ..write(' stroke="${_color(color)}"')
      ..write(' stroke-width="${_n(width)}"')
      ..write(' stroke-linecap="round"');
    if (dashed) _buffer.write(' stroke-dasharray="6 4"');
    _buffer.write('/>');
  }

  static String _color(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    final a = (argb >> 24) & 0xFF;
    if (a == 0xFF) {
      final hex = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
      return '#$hex';
    }
    return 'rgba($r,$g,$b,${_n(a / 255)})';
  }

  static String _n(double value) {
    final rounded = value.toStringAsFixed(2);
    return rounded.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// [text] as XML character data: the markup characters escaped, and the
  /// control characters XML has no place for dropped.
  static String _escape(String text) => text
      .replaceAll(_notXml, '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
