import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_density.dart';

/// An on/off switch drawn for the device that holds it (#1125).
///
/// Material's [Switch] is a touch control: a 52 x 32 track inside a 48 px
/// target, which beside the compact controls of a desktop reads as a phone
/// control blown up. `SwitchThemeData` has no size and visual density does
/// not reach a [Switch], so every switch in the app is this one:
///
///  * on a thumb's theme (see `pointerDense`) it is Material's own switch,
///    unchanged;
///  * on a pointer's theme it is the same [Switch] drawn at [pointerScale]
///    of its size, and it takes the room it draws: no 48 px target around
///    a track a mouse can aim at, and nothing for the layout to centre
///    in empty padding.
///
/// `test/unit/switch_sources_test.dart` keeps a raw [Switch] out of the
/// rest of `lib`.
final class AppSwitch extends StatelessWidget {
  /// A switch that is [value], and calls [onChanged] with the other state
  /// when it is flipped; a null [onChanged] disables it.
  const new({required this.value, required this.onChanged, super.key});

  /// Material's track width, the size the switch is laid out at before it
  /// is scaled on a pointer's theme.
  static const double trackWidth = 52;

  /// Material's track height.
  static const double trackHeight = 32;

  /// How much of Material's size a pointer's switch is drawn at: a 37 x 23
  /// track, in step with the 32 px rows of a desktop's menus.
  static const double pointerScale = 0.72;

  /// Whether it is on.
  final bool value;

  /// Flips it; null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (thumbDense(Theme.of(context))) {
      return Switch(value: value, onChanged: onChanged);
    }
    // The switch is laid out at Material's size, with no target around its
    // track, and scaled as a whole: the hover and focus halo, the thumb and
    // the track shrink together, and are drawn from vectors at the size they
    // show. The box around it is the drawn size, so a row sees 37 x 23.
    return SizedBox(
      width: trackWidth * pointerScale,
      height: trackHeight * pointerScale,
      child: FittedBox(
        child: SizedBox(
          width: trackWidth,
          height: trackHeight,
          child: Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
