/// The button on the row of a PDF or a book that copies a link to the
/// place being read (#282), for a note to point there.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/place_link.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/ui/strings.dart';

/// Where a reader is, as a link needs it: the file's library-relative
/// path, the place, and what the link shows.
typedef PlaceToLink = ({String path, BookLocation place, String label});

/// Copies a link to the place [here] says, as the library writes links.
final class PlaceLinkButton extends StatelessWidget {
  /// A button asking [here] for the place; null disables it (a file
  /// outside a library, one not shown yet), keeping it on the row.
  const new({required this.here, required this.linkType, super.key});

  /// The place being read, or null when there is none to link to.
  final PlaceToLink? Function()? here;

  /// How the library writes links.
  final LinkType linkType;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('place-link-button'),
    tooltip: AppStrings.copyPlaceLink,
    icon: const Icon(Icons.link),
    visualDensity: VisualDensity.compact,
    onPressed: here == null
        ? null
        : () {
            final at = here?.call();
            if (at != null) unawaited(copyPlaceLink(context, at, linkType));
          },
  );
}

/// Copies the link to [at], as [linkType] writes links, and says so.
Future<void> copyPlaceLink(
  BuildContext context,
  PlaceToLink at,
  LinkType linkType,
) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(
    ClipboardData(
      text: placeLink(
        path: at.path,
        place: at.place,
        label: at.label,
        linkType: linkType,
      ),
    ),
  );
  messenger.showSnackBar(SnackBar(content: Text(AppStrings.placeLinkCopied)));
}
