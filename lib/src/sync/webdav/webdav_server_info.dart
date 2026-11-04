import 'package:meta/meta.dart';

/// What `OPTIONS` said about the destination folder.
@immutable
final class WebDavServerInfo {
  /// Describes a server advertising [davClasses] and [allowedMethods].
  const new({required this.davClasses, required this.allowedMethods});

  /// The `DAV:` header's compliance classes, lowercased (`1`, `2`, `3`,
  /// `access-control`, …); empty when the header is missing.
  final Set<String> davClasses;

  /// The `Allow:` header's methods, uppercased; empty when missing.
  final Set<String> allowedMethods;

  /// Whether the server claims WebDAV class 1.
  bool get isWebDav => davClasses.contains('1');

  /// Whether [method] is allowed — assumed when the server lists nothing.
  bool allows(String method) =>
      allowedMethods.isEmpty || allowedMethods.contains(method.toUpperCase());
}
