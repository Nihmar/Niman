import 'package:flutter/material.dart';
import 'package:niman/src/ui/settings_rows.dart';

/// A setting on a scale with its slider in the row (#712): a desktop's
/// shape, where the phone's row opens a dialog with the slider in it. The
/// value reads at the slider's end; a drag is kept when it is let go, a
/// key's step at once.
final class SettingsSliderRow extends StatefulWidget {
  /// Creates the row for [title], reading [value] between [min] and [max].
  const new({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
    this.subtitle,
    this.divisions,
    this.sliderKey,
    this.enabled = true,
    super.key,
  });

  /// Whether the setting can be changed now; false greys the row out.
  final bool enabled;

  /// The setting's name.
  final String title;

  /// What it does, under the title.
  final String? subtitle;

  /// The value now.
  final double value;

  /// The scale's low end.
  final double min;

  /// The scale's high end.
  final double max;

  /// The steps the slider snaps to; null leaves it continuous.
  final int? divisions;

  /// The value as the row reads it.
  final String Function(double value) format;

  /// Keeps a new value.
  final ValueChanged<double> onChanged;

  /// The slider's key, for tests.
  final Key? sliderKey;

  @override
  State<SettingsSliderRow> createState() => _SettingsSliderRowState();
}

final class _SettingsSliderRowState extends State<SettingsSliderRow> {
  /// The value under a drag, kept once it is let go.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final shown = _dragging ?? widget.value;
    return SettingsRowFrame(
      title: widget.title,
      description: widget.subtitle,
      enabled: widget.enabled,
      control: Row(
        children: [
          Expanded(
            child: Slider(
              key: widget.sliderKey,
              value: shown.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChangeStart: (value) => setState(() => _dragging = value),
              onChanged: !widget.enabled
                  ? null
                  : (value) {
                      if (_dragging == null) {
                        widget.onChanged(value);
                      } else {
                        setState(() => _dragging = value);
                      }
                    },
              onChangeEnd: (value) {
                setState(() => _dragging = null);
                widget.onChanged(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.format(shown)),
        ],
      ),
    );
  }
}
