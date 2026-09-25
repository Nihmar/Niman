/// Where a file the user saved landed (#24), as a message and the OS want
/// it.
///
/// `FilePicker.saveFile` answers a [Uri] whose scheme depends on the
/// platform: `file` on the desktop, `content` on Android, `blob`/`http` on
/// the web. A `file:` URI is a path spelled the URI way, which is neither
/// what a snackbar should read to a user nor what the file manager takes:
/// `File('file:///home/x/a.md')` does not exist. Every other scheme has no
/// path of ours, and is shown as it is.
library;

import 'dart:io';

/// The place [uri] names: its path when it is a `file:` URI, its own text
/// otherwise.
String savedPlace(Uri uri) => uri.scheme == 'file'
    ? uri.toFilePath(windows: Platform.isWindows)
    : uri.toString();
