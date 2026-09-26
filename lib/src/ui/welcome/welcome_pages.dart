/// The welcome deck's pages (#266): title, body, and which platform sees
/// them, in one table so the order and the copy are reviewable here.
library;

import 'dart:io';

import 'package:niman/src/ui/welcome/welcome_copy.dart';

/// One page of the deck.
final class WelcomePage {
  /// Creates a page.
  const new({required this.title, required this.body});

  /// The page's heading.
  final String title;

  /// The page's prose.
  final String body;
}

/// The themed pages, in order: the ones every platform shares.
///
/// The device page is not here — it is [devicePage] and draws what this
/// platform has — and neither is the question, which is not prose.
List<WelcomePage> themedPages(WelcomeCopy copy) => [
  WelcomePage(title: copy.notesTitle, body: copy.notesBody),
  WelcomePage(title: copy.modesTitle, body: copy.modesBody),
  WelcomePage(title: copy.linksTitle, body: copy.linksBody),
  WelcomePage(title: copy.findTitle, body: copy.findBody),
  WelcomePage(title: copy.exportTitle, body: copy.exportBody),
  WelcomePage(title: copy.tasksTitle, body: copy.tasksBody),
  WelcomePage(title: copy.syncTitle, body: copy.syncBody),
];

/// The device page: one body, whichever platform this is.
///
/// Android gets the share sheet, the home-screen widgets and voice notes;
/// a desktop gets the tray, the panes and the file association. The page
/// exists on every platform — it says what *this* one can do.
WelcomePage devicePage(WelcomeCopy copy, {bool? isAndroid}) => WelcomePage(
  title: copy.deviceTitle,
  body: (isAndroid ?? Platform.isAndroid) ? copy.androidBody : copy.desktopBody,
);
