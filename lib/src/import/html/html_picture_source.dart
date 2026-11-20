/// Where a picture of an imported page (#1293) is to be had: a file beside
/// the page, a web address, or the page itself (a `data:` address).
library;

import 'package:path/path.dart' as p;

/// What kind of place a picture is at.
enum PictureKind {
  /// A file on this device.
  local,

  /// An http or https address.
  web,

  /// A `data:` address: the picture is in the address.
  data,
}

/// Where one picture is, as its `src` names it.
final class PictureSource {
  /// A picture of [kind] at [address]: an absolute file path, an absolute
  /// web address, or a `data:` address.
  const new(this.kind, this.address);

  /// Reads [src], as a page wrote it, against [base] — the page's file
  /// (`Uri.file`), or the address its `<base href>` names.
  ///
  /// A `src` that names a place is read as a browser reads it: relative to
  /// [base], percent-decoded for a file, `//host/x.png` over https, a
  /// backslash a slash in a path a browser on Windows saved. Null for one
  /// that names none (an empty `src`, another scheme).
  static PictureSource? parse(String src, Uri base) {
    final text = src.trim();
    if (text.isEmpty) return null;
    if (text.toLowerCase().startsWith('data:')) {
      return PictureSource(PictureKind.data, text);
    }
    // A path of Windows, written as one (`C:/pics/a.png`).
    if (_drivePath.hasMatch(text)) {
      return PictureSource(
        PictureKind.local,
        p.normalize(Uri.file(text, windows: true).toFilePath()),
      );
    }
    final reference = text.startsWith('//')
        ? 'https:$text'
        : _hasScheme(text)
        ? text
        : text.replaceAll(r'\', '/');
    final Uri resolved;
    try {
      resolved = base.resolveUri(Uri.parse(reference));
    } on FormatException {
      return null;
    }
    if (resolved.isScheme('http') || resolved.isScheme('https')) {
      return resolved.host.isEmpty
          ? null
          : PictureSource(
              PictureKind.web,
              resolved.removeFragment().toString(),
            );
    }
    if (resolved.isScheme('file')) {
      // Without its query and fragment: `toFilePath` refuses them.
      final plain = Uri(
        scheme: 'file',
        host: resolved.host,
        path: resolved.path,
      );
      try {
        return PictureSource(
          PictureKind.local,
          p.normalize(plain.toFilePath()),
        );
      } on Object {
        return null;
      }
    }
    return null;
  }

  /// What kind of place it is.
  final PictureKind kind;

  /// Where: an absolute path, an absolute address, or the `data:` address
  /// itself.
  final String address;

  /// A short name for it, for the progress line.
  String get label => switch (kind) {
    PictureKind.local => p.basename(address),
    PictureKind.web => address,
    PictureKind.data => 'data:',
  };

  static final RegExp _drivePath = RegExp(r'^[a-zA-Z]:[\\/]');

  static bool _hasScheme(String text) =>
      RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text);
}
