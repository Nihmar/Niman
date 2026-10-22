/// What the Features screen says about a row (#1109): its icon and the line
/// that tells what *off* means.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/strings.dart';

/// [feature]'s outline icon. The same ones the rest of the app draws it with:
/// a filled icon would say a state is on.
///
/// An exhaustive `switch`, like the classifiers: a feature added without an
/// icon does not compile.
IconData featureIcon(LibraryFeature feature) => switch (feature) {
  LibraryFeature.search => Icons.search,
  LibraryFeature.quickNote => Icons.edit_outlined,
  LibraryFeature.templates => Icons.library_books_outlined,
  LibraryFeature.capture => Icons.language_outlined,
  LibraryFeature.todo => Icons.check_box_outlined,
  LibraryFeature.journal => Icons.book_outlined,
  LibraryFeature.calendar => Icons.event_outlined,
  LibraryFeature.kindList => Icons.checklist_outlined,
  LibraryFeature.kindShopping => Icons.shopping_cart_outlined,
  LibraryFeature.kindAudio => Icons.mic_outlined,
  LibraryFeature.transcription => Icons.subtitles_outlined,
  LibraryFeature.kindSlides => Icons.slideshow_outlined,
  LibraryFeature.kindFlashcards => Icons.style_outlined,
  LibraryFeature.kindKanban => Icons.view_kanban_outlined,
  LibraryFeature.readers => Icons.menu_book_outlined,
  LibraryFeature.annotations => Icons.border_color_outlined,
  LibraryFeature.ocr => Icons.document_scanner_outlined,
  LibraryFeature.home => Icons.home_outlined,
  LibraryFeature.widgets => Icons.widgets_outlined,
};

/// What turning [feature] off means, as the row says it under the name.
///
/// The five note kinds say the same sentence: their notes open as plain
/// Markdown and keep their `type:`.
String featureOffLine(LibraryFeature feature) => switch (feature) {
  LibraryFeature.search => AppStrings.featureOffSearch,
  LibraryFeature.quickNote => AppStrings.featureOffQuickNote,
  LibraryFeature.templates => AppStrings.featureOffTemplates,
  LibraryFeature.capture => AppStrings.featureOffCapture,
  LibraryFeature.todo => AppStrings.featureOffTodo,
  LibraryFeature.journal => AppStrings.featureOffJournal,
  LibraryFeature.calendar => AppStrings.featureOffCalendar,
  LibraryFeature.kindList ||
  LibraryFeature.kindShopping ||
  LibraryFeature.kindAudio ||
  LibraryFeature.kindSlides ||
  LibraryFeature.kindFlashcards ||
  LibraryFeature.kindKanban => AppStrings.featureOffKind,
  LibraryFeature.transcription => AppStrings.featureOffTranscription,
  LibraryFeature.readers => AppStrings.featureOffReaders,
  LibraryFeature.annotations => AppStrings.featureOffAnnotations,
  LibraryFeature.ocr => AppStrings.featureOffOcr,
  LibraryFeature.home => AppStrings.featureOffHome,
  LibraryFeature.widgets => AppStrings.featureOffWidgets,
};
