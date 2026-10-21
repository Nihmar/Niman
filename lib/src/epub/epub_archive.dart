/// An EPUB's zip, read within bounds (#1138).
///
/// A book is a zip from the internet and can be hostile: a few kilobytes of
/// deflate that expand to gigabytes, or a directory of a million entries.
/// The archive is decoded from the file — never held whole — its entry count
/// and the sizes its entries declare are checked before anything is
/// inflated, and every entry is inflated against what is left of the budget,
/// so an entry that lies about its size is stopped where it passes it
/// (`bounded_entry.dart`, the Notion import's reader).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/import/bounded_entry.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// The most a book may expand to, in uncompressed bytes.
const int epubMaxBytes = 1 << 30;

/// The most files a book may hold.
const int epubMaxEntries = 100000;

/// The most one file read as text may expand to, in uncompressed bytes.
///
/// The total budget lets a single entry take the whole gigabyte, and a text
/// entry costs several times its size once read: decoded to a string (two
/// bytes a character), then parsed into a DOM (an order of magnitude more),
/// on a phone. A novel is about a megabyte of text and its chapters' XHTML a
/// few at the most, a whole library's worth in one file ten; 32 MiB leaves
/// a book written as one file markup and all several times over, and stops
/// what only a hostile or broken book is.
const int epubMaxTextBytes = 32 << 20;

/// Why a file could not be read as a book.
enum EpubRefusal {
  /// Not an EPUB: not a zip, or one without a package document or chapters.
  notABook,

  /// Its text is encrypted (DRM): there is nothing readable to show or keep.
  protected,

  /// It holds more entries, or expands to more, than a book can.
  tooLarge,
}

/// A file that is not a book this app can read, and why. A
/// [FormatException], as the reader's refusals always were.
final class EpubRefused extends FormatException {
  /// Refuses a book for [reason]; [detail] is for the log.
  const new(this.reason, String detail) : super(detail);

  /// Why.
  final EpubRefusal reason;

  /// What exactly, for the log.
  String get detail => message;

  @override
  String toString() => 'EpubRefused(${reason.name}): $message';
}

/// The zip of a book, decoded from its file and read within a budget.
final class EpubArchive {
  /// Decodes [input]'s directory, refusing a zip past the bounds: [maxBytes]
  /// for all its entries together, [maxEntries] files, and [maxTextBytes]
  /// for any one read as text.
  ///
  /// Throws [EpubRefused].
  factory open(
    InputStream input, {
    int maxBytes = epubMaxBytes,
    int maxEntries = epubMaxEntries,
    int maxTextBytes = epubMaxTextBytes,
  }) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } on Object catch (error) {
      throw EpubRefused(EpubRefusal.notABook, 'not a zip: $error');
    }
    if (archive.length > maxEntries) {
      throw EpubRefused(
        EpubRefusal.tooLarge,
        '${archive.length} entries, over $maxEntries',
      );
    }
    final declared = archive.fold<int>(0, (sum, file) => sum + file.size);
    if (declared > maxBytes) {
      throw EpubRefused(
        EpubRefusal.tooLarge,
        'its entries expand to $declared bytes, over $maxBytes',
      );
    }
    return EpubArchive._(archive, maxBytes, maxTextBytes);
  }

  new _(this._archive, this._maxBytes, this._maxTextBytes);

  final Archive _archive;
  final int _maxBytes;
  final int _maxTextBytes;
  int _read = 0;

  /// Whether the zip holds [path].
  bool has(String path) => _archive.findFile(path) != null;

  /// The bytes of [path], or null when the zip does not hold it. Throws
  /// [EpubRefused] when reading it would pass the budget, or [limit] when
  /// that is given.
  Uint8List? bytes(String path, {int? limit}) {
    final file = _archive.findFile(path);
    if (file == null) return null;
    final left = _maxBytes - _read;
    final within = limit == null || limit > left ? left : limit;
    final Uint8List? bytes;
    try {
      bytes = readEntryWithin(file, within);
    } on EntryOverBudget {
      throw EpubRefused(
        EpubRefusal.tooLarge,
        within == left
            ? '"$path" expands past the $_maxBytes-byte budget'
            : '"$path" expands past the $within bytes one file may',
      );
    } finally {
      // The inflated bytes are cached on the entry: let them go.
      file.clear();
    }
    _read += bytes?.length ?? 0;
    return bytes ?? Uint8List(0);
  }

  /// [path] as text, or null when the zip does not hold it. Throws
  /// [EpubRefused] when it expands past what one file read as text may.
  String? text(String path) {
    final bytes = this.bytes(path, limit: _maxTextBytes);
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }

  /// [path] parsed as XML. Throws [EpubRefused] when it is missing or not
  /// XML.
  XmlDocument xml(String path) {
    final text = this.text(path);
    if (text == null) {
      throw EpubRefused(EpubRefusal.notABook, '"$path" is not in the book');
    }
    try {
      return XmlDocument.parse(text);
    } on XmlException catch (error) {
      throw EpubRefused(EpubRefusal.notABook, '"$path" is not XML: $error');
    }
  }

  /// The package document's path, from `META-INF/container.xml`.
  String packagePath() {
    final container = xml('META-INF/container.xml');
    final rootfile = container.descendantElements
        .where((element) => element.localName == 'rootfile')
        .firstOrNull;
    final path = rootfile?.getAttribute('full-path');
    if (path == null) {
      throw const EpubRefused(EpubRefusal.notABook, 'no package document');
    }
    return path;
  }

  /// The files `META-INF/encryption.xml` says are encrypted, as paths in the
  /// zip; empty when it has none. A font obfuscated against copying is
  /// listed there too, and is harmless: the caller asks about its text.
  Set<String> encrypted() {
    if (!has('META-INF/encryption.xml')) return const {};
    final XmlDocument document;
    try {
      document = xml('META-INF/encryption.xml');
    } on EpubRefused {
      return const {};
    }
    return {
      for (final reference in document.descendantElements)
        if (reference.localName == 'CipherReference')
          if (reference.getAttribute('URI') case final uri?)
            p.posix.normalize(percentDecoded(uri)),
    };
  }
}

/// Whether the file at [path] is an EPUB, whatever it is called: the format
/// opens its zip on a `mimetype` entry, stored as it is, that says
/// `application/epub+zip`. A shared book can come named `msf:1234`, with
/// nothing in its name to tell it by (#1138).
Future<bool> looksLikeEpub(String path) async {
  RandomAccessFile? file;
  try {
    file = await File(path).open();
    final head = await file.read(128);
    if (head.length < 58) return false;
    // A zip's local file header, its name at 30 and its data after the name
    // and the extra field.
    if (head[0] != 0x50 || head[1] != 0x4B || head[2] != 3 || head[3] != 4) {
      return false;
    }
    final nameLength = head[26] | (head[27] << 8);
    final extraLength = head[28] | (head[29] << 8);
    final dataAt = 30 + nameLength + extraLength;
    if (nameLength != 8 || dataAt + _epubMime.length > head.length) {
      return false;
    }
    return ascii.decode(head.sublist(30, 38), allowInvalid: true) ==
            'mimetype' &&
        ascii.decode(
              head.sublist(dataAt, dataAt + _epubMime.length),
              allowInvalid: true,
            ) ==
            _epubMime;
  } on FileSystemException {
    return false;
  } finally {
    await file?.close();
  }
}

const String _epubMime = 'application/epub+zip';
