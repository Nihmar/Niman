/// The colour `==highlighted==` text is marked with (#279): a highlighter's
/// yellow, see-through so the text keeps its own colour on it, and quieter
/// at night, where a bright wash glares.
///
/// The same in every palette, as a highlighter is: the colour says "marked"
/// the way it does on paper, whichever theme the page wears.
library;

import 'package:flutter/painting.dart';

/// The mark on a light page.
const Color markHighlightLight = Color(0x66FFD60A);

/// The mark on a dark page.
const Color markHighlightDark = Color(0x4DFFD60A);

/// The mark for a page that is [dark] or not.
Color markHighlightFor({required bool dark}) =>
    dark ? markHighlightDark : markHighlightLight;
