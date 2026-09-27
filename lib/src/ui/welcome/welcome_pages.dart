/// The welcome deck's pages (#266): title, body, and which platform sees
/// them, in one table so the order and the copy are reviewable here.
library;

import 'dart:io';

import 'package:niman/src/ui/strings.dart';

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
List<WelcomePage> themedPages() => [
  WelcomePage(
    title: AppStrings.welcomeNotesTitle,
    body: AppStrings.welcomeNotesBody,
  ),
  WelcomePage(
    title: AppStrings.welcomeModesTitle,
    body: AppStrings.welcomeModesBody,
  ),
  WelcomePage(
    title: AppStrings.welcomeLinksTitle,
    body: AppStrings.welcomeLinksBody,
  ),
  WelcomePage(
    title: AppStrings.welcomeFindTitle,
    body: AppStrings.welcomeFindBody,
  ),
  WelcomePage(
    title: AppStrings.welcomeExportTitle,
    body: AppStrings.welcomeExportBody,
  ),
  WelcomePage(
    title: AppStrings.welcomeTasksTitle,
    body: AppStrings.welcomeTasksBody,
  ),
  WelcomePage(
    title: AppStrings.welcomeSyncTitle,
    body: AppStrings.welcomeSyncBody,
  ),
];

/// The device page: one body, whichever platform this is.
///
/// Android gets the share sheet, the home-screen widgets and voice notes;
/// a desktop gets the tray, the panes and the file association. The page
/// exists on every platform — it says what *this* one can do.
WelcomePage devicePage({bool? isAndroid}) => WelcomePage(
  title: AppStrings.welcomeDeviceTitle,
  body: (isAndroid ?? Platform.isAndroid)
      ? AppStrings.welcomeAndroidBody
      : AppStrings.welcomeDesktopBody,
);
