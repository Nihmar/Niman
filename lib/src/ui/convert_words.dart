/// The words a conversion into notes writes (#1138, #1294), in the
/// interface's language: the isolate that writes has no locale, so they are
/// handed in. A book is converted the same way, whether it was an EPUB or a
/// web page.
library;

import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/ui/strings.dart';

/// The words a conversion writes, in the interface's language.
BookWords convertWords() => (
  chapter: AppStrings.convertChapterName,
  opening: AppStrings.convertOpening,
  contents: AppStrings.convertContents,
);
