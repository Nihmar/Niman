// Resolves the native directory picker's result into the real
// filesystem path of the library root.
//
// With the persistent SAF grant, the Android picker hands back the
// external-storage tree URI (a
// `content://com.android.externalstorage.documents/tree/...` string)
// rather than a path. The provider's tree document IDs have the form
// `<volume>:<path>` and map to the FUSE real paths the grant makes
// accessible: volume `primary` is `/storage/emulated/0`, any other
// volume is `/storage/<volume>`.

import 'package:path/path.dart' as p;

/// Maps the directory picker result [picked] to the real library root
/// path.
///
/// Returns null when [picked] is empty (the user cancelled) or when it
/// is a content URI that does not describe a folder on external
/// storage. Real paths (the Linux picker result) pass through
/// unchanged.
String? resolveLibraryRoot(String? picked) {
  final raw = (picked ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }
  // Tolerate the single-slash form `content/...` seen in the wild.
  final normalized = raw.startsWith('content/')
      ? 'content://${raw.substring(8)}'
      : raw;
  if (!normalized.startsWith('content://')) {
    return raw; // Already a real path.
  }
  final uri = Uri.parse(normalized);
  if (uri.authority != 'com.android.externalstorage.documents' ||
      !uri.pathSegments.contains('tree')) {
    return null;
  }
  // pathSegments are already percent-decoded.
  final documentId = uri.pathSegments.last;
  final colon = documentId.indexOf(':');
  if (colon <= 0) {
    return null;
  }
  final volumeId = documentId.substring(0, colon);
  final docPath = documentId.substring(colon + 1);
  final volumeRoot = volumeId == 'primary'
      ? '/storage/emulated/0'
      : '/storage/$volumeId';
  return docPath.isEmpty ? volumeRoot : p.join(volumeRoot, docPath);
}
