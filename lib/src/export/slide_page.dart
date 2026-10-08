import 'package:flutter/painting.dart';

/// The size a slide is laid out at, in logical pixels (#534): one layout,
/// scaled to the pane, the projector, the thumbnails and the PDF alike, so
/// the page and the screen show the same slide.
const Size slideSize = Size(960, 540);

/// The margin round a slide's text, on screen and on the page.
const EdgeInsets slidePadding = EdgeInsets.symmetric(
  horizontal: 64,
  vertical: 40,
);

/// How much larger than a note's text a slide's is: a 16 px line on a
/// 960 px slide reads as a footnote on a projector.
const double slideTextScale = 1.8;
