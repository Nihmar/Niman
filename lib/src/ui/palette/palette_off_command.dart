import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/palette/palette_command.dart';

/// A command the palette would offer but for its `feature` being off
/// (#1109): kept to say why a query found nothing.
typedef PaletteOffCommand = ({PaletteCommand command, LibraryFeature feature});
