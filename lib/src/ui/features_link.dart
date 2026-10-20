/// Where the links to Settings → Features lead (#1109).
///
/// The palette's quiet line and the Navigation area both say a feature is
/// off and point to the switch. They point here, and nowhere else: the
/// Features area is the Library group's first row, and this is the one
/// place that names it.
library;

import 'package:niman/src/ui/settings_areas.dart';

/// The place the links to Features open: the Library group of Settings,
/// at its first row.
const SettingsTarget featuresTarget = (
  area: SettingsAreaId.features,
  row: null,
);
