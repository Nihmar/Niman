/// Which files are web pages the app converts into notes (#1293).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// The extensions of a web page saved as a file, lower case with the dot.
const Set<String> htmlExtensions = {'.html', '.htm', '.xhtml'};

/// The same, without the dot: what a file picker filters by.
const List<String> htmlPickerExtensions = ['html', 'htm', 'xhtml'];

/// Whether [path] (or a bare file name) is a web page by its extension, in
/// any case.
bool isHtmlFile(String path) =>
    htmlExtensions.contains(p.extension(path).toLowerCase());

/// Whether the file at [path] begins as a web page does: a document type or
/// an `<html` tag, after a byte-order mark and any white space.
///
/// For a share whose provider gave the file no extension (`msf:1234`): the
/// only way left to tell a page from a text. It reads the first bytes
/// asynchronously, so it is safe on the UI isolate, and answers false for a
/// file it cannot read.
Future<bool> looksLikeHtml(String path) async {
  try {
    final file = await File(path).open();
    final Uint8List head;
    try {
      head = await file.read(512);
    } finally {
      await file.close();
    }
    return htmlStart.hasMatch(String.fromCharCodes(head.where((b) => b != 0)));
  } on FileSystemException {
    return false;
  }
}

/// A document type or an `<html` tag at the start of a file, past a BOM
/// (UTF-8's or UTF-16's, read as Latin-1) and white space. A UTF-16 file's
/// NULs are dropped before it is matched.
final RegExp htmlStart = RegExp(
  r'^[\uFEFF\u00EF\u00BB\u00BF\u00FF\u00FE\s]*<(?:!doctype\s+html|html[\s>])',
  caseSensitive: false,
);
