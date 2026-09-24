// The color picker the theme editor opens (issue #269).
//
// Three ways into the same color: a square for saturation and value, a
// bar for the hue, and the field that spells it out. Whoever knows the
// hex types it; whoever does not can still find a color by eye, and the
// two are always in step.
//
// What comes back is rounded to `#RRGGBB`, which is what a theme is
// stored as: a picked color that changed when saved would be a preview
// that lied.

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks for a color, starting from [initial]; null when dismissed.
///
/// [title] names what is being colored — a theme role, in the editor.
Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required String title,
  required Color initial,
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) => _ColorPickerDialog(title: title, initial: initial),
  );
}

final class _ColorPickerDialog extends StatefulWidget {
  const new({required this.title, required this.initial});

  final String title;
  final Color initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

final class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController _hex = TextEditingController(
    text: colorToHex(widget.initial),
  );
  String? _error;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  /// The color as it would be stored: 8-bit channels, like the field
  /// spells it.
  Color get _color => colorFromHex(colorToHex(_hsv.toColor()))!;

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _hex.text = colorToHex(value.toColor());
      _error = null;
    });
  }

  void _setHex(String text) {
    final color = colorFromHex(text);
    if (color == null) {
      setState(() => _error = AppStrings.themeEditorBadColor);
      return;
    }
    _setHsv(HSVColor.fromColor(color));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  key: const Key('color-picker-preview'),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('color-picker-hex'),
                    controller: _hex,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: '#RRGGBB',
                      errorText: _error,
                    ),
                    onChanged: _setHex,
                    onSubmitted: (_) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: const Key('color-picker-square'),
              height: 160,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onPanDown: (details) =>
                      _trackSquare(details.localPosition, constraints.biggest),
                  onPanUpdate: (details) =>
                      _trackSquare(details.localPosition, constraints.biggest),
                  child: CustomPaint(painter: _SvPainter(_hsv)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: const Key('color-picker-hue'),
              height: 24,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onPanDown: (details) =>
                      _trackHue(details.localPosition, constraints.maxWidth),
                  onPanUpdate: (details) =>
                      _trackHue(details.localPosition, constraints.maxWidth),
                  child: CustomPaint(painter: _HuePainter(_hsv.hue)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: Text(AppStrings.actionOk),
        ),
      ],
    );
  }

  /// Takes a position in the square: left is grey, right is the hue,
  /// top is as bright as it gets, bottom is black.
  void _trackSquare(Offset position, Size size) {
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = 1 - (position.dy / size.height).clamp(0.0, 1.0);
    _setHsv(_hsv.withSaturation(saturation).withValue(value));
  }

  /// Takes a position on the bar: 0° at the left, 360° at the right.
  void _trackHue(Offset position, double width) {
    final hue = (position.dx / width).clamp(0.0, 1.0) * 360;
    _setHsv(_hsv.withHue(hue));
  }
}

/// The saturation-and-value square: the pure hue, towards white to the
/// left and towards black at the bottom, which is exactly how HSV blends
/// the three.
final class _SvPainter extends CustomPainter {
  const new(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hue = hsv.withSaturation(1).withValue(1).toColor();
    final center = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    // The pure hue, white towards the left (saturation) and black towards
    // the bottom (value), which is how HSV blends the three.
    canvas
      ..drawRect(rect, Paint()..color = hue)
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.white, Color(0x00FFFFFF)],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Colors.black],
          ).createShader(rect),
      )
      // The color in hand, ringed so it reads on any of them.
      ..drawCircle(
        center,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      )
      ..drawCircle(
        center,
        8.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black54,
      );
  }

  @override
  bool shouldRepaint(_SvPainter old) => old.hsv != hsv;
}

/// The hue bar: the wheel laid out left to right, with a thumb on the hue
/// in hand.
final class _HuePainter extends CustomPainter {
  const new(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final x = (hue / 360) * size.width;
    final thumb = Offset(x, size.height / 2);
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              for (var step = 0; step <= 6; step++)
                HSVColor.fromAHSV(1, step * 60 % 360, 1, 1).toColor(),
            ],
          ).createShader(rect),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: thumb, width: 6, height: size.height + 6),
          const Radius.circular(3),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: thumb, width: 8, height: size.height + 8),
          const Radius.circular(4),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black54,
      );
  }

  @override
  bool shouldRepaint(_HuePainter old) => old.hue != hue;
}
