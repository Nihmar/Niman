/// [path] without empty segments: no leading, trailing or doubled `/`.
String webDavCleanPath(String path) =>
    path.split('/').where((s) => s.isNotEmpty).join('/');

/// [path] the way a log line or a failure names it: cleaned, and `/` for
/// the destination folder itself.
String webDavShowPath(String path) {
  final clean = webDavCleanPath(path);
  return clean.isEmpty ? '/' : clean;
}
