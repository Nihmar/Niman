/// Following a link in a book (#280): one into the book jumps within it,
/// a web link opens in the browser, anything else stays put.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Follows [href], tapped in [document]: a line of the book goes to
/// [jumpToLine].
void followEpubLink(
  BuildContext context,
  EpubDocument? document,
  String? href, {
  required void Function(int line) jumpToLine,
}) {
  if (href == null || href.isEmpty) return;
  if (href.startsWith('${EpubDocument.linkScheme}:')) {
    final line = document?.lineOfLink(href);
    if (line != null) jumpToLine(line);
    return;
  }
  final uri = Uri.tryParse(href);
  if (uri == null || !uri.hasScheme) return;
  unawaited(_launch(context, uri));
}

Future<void> _launch(BuildContext context, Uri uri) async {
  var launched = false;
  try {
    launched = await launchUrl(uri);
  } on Object {
    launched = false;
  }
  if (launched || !context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(AppStrings.openLinkFailed)));
}
