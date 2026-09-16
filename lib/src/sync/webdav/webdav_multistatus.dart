import 'dart:io' show HttpDate, HttpException;

import 'package:meta/meta.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:xml/xml.dart';

/// The `DAV:` namespace.
const String davNamespace = 'DAV:';

/// The ownCloud / Nextcloud namespace (`oc:fileid`, `oc:checksums`).
const String ocNamespace = 'http://owncloud.org/ns';

/// The PROPFIND body the client sends: the properties the sync reads, by
/// name. Never `allprop`, which makes some servers compute expensive
/// properties (quota, dead properties) for every item.
const String propfindBody =
    '<?xml version="1.0" encoding="utf-8"?> '
    '<d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns"> '
    '<d:prop>'
    '<d:resourcetype/>'
    '<d:getetag/>'
    '<d:getcontentlength/>'
    '<d:getlastmodified/>'
    '<oc:fileid/>'
    '<oc:checksums/>'
    '</d:prop>'
    '</d:propfind>';

/// One item of a PROPFIND answer.
@immutable
final class WebDavResource {
  /// Describes the item at [path].
  const new({
    required this.path,
    required this.isCollection,
    this.etag,
    this.size,
    this.modified,
    this.fileId,
    this.checksums = const {},
  });

  /// Relative to the client's base URL, decoded, `/`-separated, with no
  /// leading or trailing slash; `''` is the base folder itself.
  final String path;

  /// Whether the item is a folder.
  final bool isCollection;

  /// `getetag` exactly as sent (quotes and `W/` included, as `If-Match`
  /// needs it), or null when the server has none.
  final String? etag;

  /// `getcontentlength`, or null (folders, servers that omit it).
  final int? size;

  /// `getlastmodified` in UTC (one-second resolution), or null.
  final DateTime? modified;

  /// `oc:fileid`, or null.
  final String? fileId;

  /// `oc:checksums` as lowercase algorithm → lowercase hex, e.g.
  /// `{'sha1': '…'}`; empty when the server offers none.
  final Map<String, String> checksums;

  /// The last path segment; `''` for the base folder.
  String get name => path.substring(path.lastIndexOf('/') + 1);

  @override
  bool operator ==(Object other) =>
      other is WebDavResource &&
      other.path == path &&
      other.isCollection == isCollection &&
      other.etag == etag &&
      other.size == size &&
      other.modified == modified &&
      other.fileId == fileId &&
      _sameMap(other.checksums, checksums);

  @override
  int get hashCode =>
      Object.hash(path, isCollection, etag, size, modified, fileId);

  @override
  String toString() =>
      'WebDavResource(${path.isEmpty ? '.' : path}'
      '${isCollection ? '/' : ', ${size ?? '?'} b'}'
      '${etag == null ? '' : ', etag $etag'})';
}

bool _sameMap(Map<String, String> a, Map<String, String> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// The items of a `207 Multi-Status` [body], with paths made relative to
/// [base] (the folder URL the client was created with, trailing slash
/// included).
///
/// Tolerant the way real servers need: any namespace prefix, elements
/// with no namespace at all, hrefs as absolute URLs or absolute paths,
/// percent-encoded in any style, property values in several propstats.
/// Only `200` propstats count. A response whose href lies outside [base]
/// is reported through [onSkipped] and left out; an unparsable document
/// throws [WebDavProtocolFailure].
///
/// A server behind a reverse proxy that mounts it under a path prefix
/// answers with the hrefs it knows — its own, without the prefix the
/// client asked through. [_prefixDrop] works out how many leading
/// segments of [base] the answer leaves off, so those hrefs still
/// resolve; see its doc for what keeps that from accepting anything.
List<WebDavResource> parseMultistatus(
  String body,
  Uri base, {
  void Function(String href)? onSkipped,
}) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(body);
  } on XmlException catch (e) {
    throw WebDavProtocolFailure('unparsable multistatus: ${e.message}');
  }
  final root = document.rootElement;
  if (!_isDav(root, 'multistatus')) {
    throw WebDavProtocolFailure(
      'expected a multistatus, got <${root.localName}>',
    );
  }
  final baseSegments = _segments(base);
  final responses = _children(root, 'response').toList();
  final hrefs = <String?>[
    for (final response in responses)
      _children(response, 'href').firstOrNull?.innerText.trim(),
  ];
  final expected = baseSegments.sublist(
    _prefixDrop(hrefs, base, baseSegments),
  );
  final resources = <WebDavResource>[];
  for (var i = 0; i < responses.length; i++) {
    final response = responses[i];
    final href = hrefs[i];
    if (href == null || href.isEmpty) continue;
    final relative = _relativePath(href, base, expected);
    if (relative == null) {
      onSkipped?.call(href);
      continue;
    }
    final props = <XmlElement>[
      for (final propstat in _children(response, 'propstat'))
        if (_isOk(propstat))
          for (final prop in _children(propstat, 'prop')) ...prop.childElements,
    ];
    XmlElement? find(String local, [String namespace = davNamespace]) {
      for (final prop in props) {
        if (prop.localName == local &&
            (prop.namespaceUri == namespace || prop.namespaceUri == null)) {
          return prop;
        }
      }
      return null;
    }

    final resourceType = find('resourcetype');
    final isCollection =
        (resourceType != null &&
            _children(resourceType, 'collection').isNotEmpty) ||
        href.endsWith('/');
    resources.add(
      WebDavResource(
        path: relative,
        isCollection: isCollection,
        etag: _text(find('getetag')),
        size: int.tryParse(_text(find('getcontentlength')) ?? ''),
        modified: _date(_text(find('getlastmodified'))),
        fileId: _text(find('fileid', ocNamespace)),
        checksums: _checksums(find('checksums', ocNamespace)),
      ),
    );
  }
  return resources;
}

bool _isDav(XmlElement element, String local) =>
    element.localName == local &&
    (element.namespaceUri == davNamespace || element.namespaceUri == null);

Iterable<XmlElement> _children(XmlElement parent, String local) =>
    parent.childElements.where((e) => _isDav(e, local));

/// Whether a propstat's `status` is a 2xx (most say `HTTP/1.1 200 OK`).
bool _isOk(XmlElement propstat) {
  final status = _children(propstat, 'status').firstOrNull?.innerText;
  if (status == null) return true;
  final code = RegExp(r'\s(\d{3})\b').firstMatch(' $status')?.group(1);
  return code != null && code.startsWith('2');
}

String? _text(XmlElement? element) {
  final text = element?.innerText.trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(String? text) {
  if (text == null) return null;
  try {
    return HttpDate.parse(text);
  } on HttpException {
    return DateTime.tryParse(text)?.toUtc();
  }
}

/// `<oc:checksum>SHA1:ab MD5:cd</oc:checksum>` → `{sha1: ab, md5: cd}`.
Map<String, String> _checksums(XmlElement? element) {
  if (element == null) return const {};
  final result = <String, String>{};
  for (final token in element.innerText.split(RegExp(r'\s+'))) {
    final colon = token.indexOf(':');
    if (colon <= 0 || colon == token.length - 1) continue;
    result[token.substring(0, colon).toLowerCase()] = token
        .substring(colon + 1)
        .toLowerCase();
  }
  return result;
}

/// Decoded, non-empty path segments of [uri].
List<String> _segments(Uri uri) => [
  for (final segment in uri.pathSegments)
    if (segment.isNotEmpty) segment,
];

/// A `%` not followed by two hex digits, which decoding would reject.
final _badEscape = RegExp('%(?![0-9a-fA-F]{2})');

/// How many leading segments of [baseSegments] the server's hrefs leave
/// off, which is what a reverse proxy mounting it under a path prefix
/// costs: the client asks through `/omv/webdav/…`, the server answers
/// about `/webdav/…` because that is the only path it knows.
///
/// Chosen as the drop that places the most hrefs inside the
/// destination, ties going to the smallest — so a server that needs no
/// allowance keeps the exact match, and one href cannot move the
/// mapping for the rest. The last segment of [base] is never dropped:
/// the destination folder's own name always has to appear, so this
/// widens what counts as inside the destination by a known prefix
/// rather than accepting anything the server cares to name.
int _prefixDrop(List<String?> hrefs, Uri base, List<String> baseSegments) {
  var best = 0;
  var bestMatches = -1;
  for (var drop = 0; drop < baseSegments.length; drop++) {
    final expected = baseSegments.sublist(drop);
    var matches = 0;
    for (final href in hrefs) {
      if (href == null || href.isEmpty) continue;
      if (_relativePath(href, base, expected) != null) matches++;
    }
    if (matches > bestMatches) {
      bestMatches = matches;
      best = drop;
    }
  }
  return best;
}

String? _relativePath(String href, Uri base, List<String> expected) {
  if (_badEscape.hasMatch(href)) return null;
  final Uri resolved;
  try {
    resolved = base.resolve(href);
  } on FormatException {
    return null;
  }
  final segments = _segments(resolved);
  if (segments.length < expected.length) return null;
  for (var i = 0; i < expected.length; i++) {
    if (segments[i] != expected[i]) return null;
  }
  return segments.sublist(expected.length).join('/');
}
