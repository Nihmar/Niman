import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// One request the fake received.
final class FakeWebDavRequest {
  /// A [method] on [path] (the raw request path) with [headers].
  const new(this.method, this.path, this.headers);

  /// The HTTP verb.
  final String method;

  /// The request path as sent (percent-encoded).
  final String path;

  /// First value of every header, lowercased names.
  final Map<String, String> headers;

  @override
  String toString() => '$method $path';
}

final class _Node {
  new folder(this.version) : folder = true, bytes = Uint8List(0);
  new file(this.bytes, this.version) : folder = false;

  final bool folder;
  Uint8List bytes;
  int version;
  DateTime modified = DateTime.utc(2000);
  late final String id = '${_ids++}'.padLeft(8, '0');

  static int _ids = 1;
}

DateTime _second(DateTime at) {
  final now = at.toUtc();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
  );
}

/// An in-memory WebDAV server on loopback for the sync tests
/// (docs/dev/sync.md, "The client").
///
/// Mounted at `/dav/`. Every optional behaviour is a switch, so one
/// server can play Nextcloud (everything on) or a bare nginx/OMV share
/// (no ETags, no preconditions, no `MOVE`).
final class FakeWebDavServer {
  new _(this._server) {
    _tree[''] = _Node.folder(_tick);
    _server.listen((request) => unawaited(_handle(request)));
  }

  /// Starts a server on a free loopback port.
  static Future<FakeWebDavServer> start() async => FakeWebDavServer._(
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
  );

  final HttpServer _server;
  final Map<String, _Node> _tree = {};
  int _tick = 1;

  /// The mount's URL, `http://127.0.0.1:<port>/dav/`.
  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}/dav/');

  /// `http://127.0.0.1:<port>`.
  Uri get origin => Uri.parse('http://127.0.0.1:${_server.port}');

  /// Every request received, in order.
  final List<FakeWebDavRequest> requests = [];

  /// Files carry `getetag` (and PUT/GET return `ETag`).
  bool etags = true;

  /// Folders carry a `getetag` that changes with their subtree.
  bool collectionEtags = true;

  /// `If-Match` / `If-None-Match` on PUT are honored.
  bool preconditions = true;

  /// A folder's `Depth: 1` listing leaves out children whose name starts
  /// with a dot, while `Depth: 0` still answers for them by path — what a
  /// real server (or the proxy in front of it) did to `.niman/`, which made
  /// the library settings "change during the sync" on every run.
  bool hideDotEntries = false;

  /// `MOVE` is implemented.
  bool supportMove = true;

  /// `oc:fileid` is served.
  bool fileIds = false;

  /// `oc:checksums` (SHA1 placeholder) is served.
  bool checksums = false;

  /// `X-OC-Mtime` is honored.
  bool ocMtime = false;

  /// `OPTIONS` sends a `DAV:` header.
  bool davHeader = true;

  /// `OPTIONS` answers 405 instead.
  bool optionsRefused = false;

  /// Namespace prefix in multistatus answers; `''` = default namespace.
  String prefix = 'D';

  /// Hrefs as absolute URLs rather than absolute paths.
  bool absoluteHrefs = false;

  /// When set, requests need Basic auth with these credentials.
  ({String user, String password})? credentials;

  /// Path prefix → redirect status + target base (absolute URL): a
  /// request under the prefix is redirected with the rest of its path.
  final Map<String, ({int status, Uri target})> redirects = {};

  /// `PROPFIND` answers 405.
  bool propfindRefused = false;

  /// `PROPFIND` on a missing path answers `207` with a `404` inside,
  /// as some servers do (#163), instead of a plain `404`.
  bool missingAsMultistatus = false;

  /// The server's clock: file mtimes (whole seconds) and the `Date`
  /// header. Tests move it to put writes in different seconds.
  DateTime Function() clock = DateTime.now;

  final List<({int status, String? retryAfter})> _failures = [];
  int _skipBeforeFailures = 0;
  int _dropGets = 0;

  /// After [after] normal requests, the next [count] answer [status]
  /// (with [retryAfter]).
  void failNext(
    int status, {
    int count = 1,
    int after = 0,
    String? retryAfter,
  }) {
    _skipBeforeFailures = after;
    for (var i = 0; i < count; i++) {
      _failures.add((status: status, retryAfter: retryAfter));
    }
  }

  /// The next GET sends half its body, then drops the connection.
  /// Forgets the failures [failNext] queued and not used yet: the server
  /// is back.
  void clearFailures() {
    _failures.clear();
    _skipBeforeFailures = 0;
  }

  void dropNextGet() => _dropGets++;

  final Map<String, int> _failPuts = {};

  /// The next PUT to [path] answers [status] (once).
  void failPutsTo(String path, int status) => _failPuts[path] = status;

  /// Removes the file or folder at [path], as another client would.
  void remove(String path) {
    _tree.removeWhere((k, _) => k == path || k.startsWith('$path/'));
    _tick++;
    _touchAncestors(path);
  }

  /// Creates or replaces the file at [path] (parents created).
  void putFile(String path, List<int> bytes) {
    _mkdirs(_parent(path));
    final node = _tree[path];
    if (node == null) {
      _tree[path] = _Node.file(Uint8List.fromList(bytes), ++_tick)
        ..modified = _second(clock());
    } else {
      node
        ..bytes = Uint8List.fromList(bytes)
        ..version = ++_tick
        ..modified = _second(clock());
    }
    _touchAncestors(path);
  }

  /// The bytes at [path], or null when there is no file.
  Uint8List? file(String path) {
    final node = _tree[path];
    return node == null || node.folder ? null : node.bytes;
  }

  /// Whether [path] is a folder.
  bool isFolder(String path) => _tree[path]?.folder ?? false;

  /// Whether anything exists at [path].
  bool exists(String path) => _tree.containsKey(path);

  /// Every path in the tree except the root, sorted.
  List<String> get paths =>
      (_tree.keys.where((k) => k.isNotEmpty).toList()..sort());

  /// Stops the server.
  Future<void> close() => _server.close(force: true);

  // --- tree ---------------------------------------------------------------

  static String _parent(String path) {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? '' : path.substring(0, slash);
  }

  void _mkdirs(String folder) {
    if (folder.isEmpty || _tree.containsKey(folder)) return;
    _mkdirs(_parent(folder));
    _tree[folder] = _Node.folder(++_tick)..modified = _second(clock());
  }

  void _touchAncestors(String path) {
    var current = path;
    while (current.isNotEmpty) {
      current = _parent(current);
      _tree[current]?.version = _tick;
    }
  }

  String _etag(_Node node) =>
      '"${node.version.toRadixString(16)}-${node.bytes.length}"';

  // --- HTTP ---------------------------------------------------------------

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    final headers = <String, String>{};
    request.headers.forEach((name, values) => headers[name] = values.first);
    requests.add(FakeWebDavRequest(request.method, request.uri.path, headers));
    request.response.headers.date = clock();
    try {
      await _route(request, headers);
    } on Object catch (e) {
      try {
        response
          ..statusCode = 500
          ..write('$e');
      } on Object catch (_) {}
    }
    try {
      await response.close();
    } on Object catch (_) {}
  }

  Future<void> _route(HttpRequest request, Map<String, String> headers) async {
    final response = request.response;
    if (_failures.isNotEmpty && _skipBeforeFailures > 0) {
      _skipBeforeFailures--;
    } else if (_failures.isNotEmpty) {
      final failure = _failures.removeAt(0);
      await request.drain<void>();
      response.statusCode = failure.status;
      if (failure.retryAfter != null) {
        response.headers.set('Retry-After', failure.retryAfter!);
      }
      return;
    }
    final expected = credentials;
    if (expected != null) {
      final token = base64.encode(
        utf8.encode('${expected.user}:${expected.password}'),
      );
      if (headers['authorization'] != 'Basic $token') {
        await request.drain<void>();
        response
          ..statusCode = 401
          ..headers.set('WWW-Authenticate', 'Basic realm="fake"');
        return;
      }
    }
    final rawPath = request.uri.path;
    for (final entry in redirects.entries) {
      if (rawPath.startsWith(entry.key)) {
        await request.drain<void>();
        final rest = rawPath.substring(entry.key.length);
        response
          ..statusCode = entry.value.status
          ..headers.set(
            'Location',
            '${entry.value.target.toString().replaceFirst(RegExp(r'/$'), '')}'
                '/$rest',
          );
        return;
      }
    }
    final segments = request.uri.pathSegments;
    if (segments.isEmpty || segments.first != 'dav') {
      await request.drain<void>();
      response.statusCode = 404;
      return;
    }
    final path = segments.skip(1).where((s) => s.isNotEmpty).join('/');
    switch (request.method) {
      case 'OPTIONS':
        await request.drain<void>();
        if (optionsRefused) {
          response.statusCode = 405;
          return;
        }
        if (davHeader) response.headers.set('DAV', '1, 2');
        response.headers.set(
          'Allow',
          'OPTIONS, GET, HEAD, PUT, DELETE, MKCOL, PROPFIND'
              '${supportMove ? ', MOVE' : ''}',
        );
      case 'PROPFIND':
        await _propfind(request, path, headers);
      case 'GET':
        await _get(request, path);
      case 'PUT':
        await _put(request, path, headers);
      case 'MKCOL':
        await request.drain<void>();
        if (_tree.containsKey(path)) {
          response.statusCode = 405;
        } else if (!(_tree[_parent(path)]?.folder ?? false)) {
          response.statusCode = 409;
        } else {
          _tree[path] = _Node.folder(++_tick)..modified = _second(clock());
          _touchAncestors(path);
          response.statusCode = 201;
        }
      case 'DELETE':
        await request.drain<void>();
        if (path.isEmpty || !_tree.containsKey(path)) {
          response.statusCode = 404;
          return;
        }
        final ifMatch = headers['if-match'];
        if (preconditions &&
            ifMatch != null &&
            ifMatch != '*' &&
            ifMatch != _etag(_tree[path]!)) {
          response.statusCode = 412;
          return;
        }
        _tree.removeWhere((k, _) => k == path || k.startsWith('$path/'));
        _tick++;
        _touchAncestors(path);
        response.statusCode = 204;
      case 'MOVE':
        await _move(request, path, headers);
      default:
        await request.drain<void>();
        response.statusCode = 405;
    }
  }

  Future<void> _propfind(
    HttpRequest request,
    String path,
    Map<String, String> headers,
  ) async {
    await request.drain<void>();
    final response = request.response;
    if (propfindRefused) {
      response.statusCode = 405;
      return;
    }
    final node = _tree[path];
    if (node == null && missingAsMultistatus) {
      final p = prefix.isEmpty ? '' : '$prefix:';
      final ns = prefix.isEmpty ? 'xmlns="DAV:"' : 'xmlns:$prefix="DAV:"';
      // The href asked for, not a resource: the status says so.
      final href = Uri(pathSegments: ['dav', ...path.split('/')]).path;
      response
        ..statusCode = 207
        ..headers.contentType = ContentType('application', 'xml')
        ..write(
          [
            '<?xml version="1.0" encoding="utf-8"?>',
            '<${p}multistatus $ns><${p}response>',
            '<${p}href>$href</${p}href>',
            '<${p}status>HTTP/1.1 404 Not Found</${p}status>',
            '</${p}response></${p}multistatus>',
          ].join(),
        );
      return;
    }
    if (node == null) {
      response.statusCode = 404;
      return;
    }
    final depth = headers['depth'];
    if (depth != '0' && depth != '1') {
      response.statusCode = 403;
      return;
    }
    final items = [
      path,
      if (depth == '1' && node.folder)
        for (final key in _tree.keys)
          if (key.isNotEmpty &&
              key != path &&
              _parent(key) == path &&
              !(hideDotEntries && key.split('/').last.startsWith('.')))
            key,
    ];
    final p = prefix.isEmpty ? '' : '$prefix:';
    final ns = prefix.isEmpty ? 'xmlns="DAV:"' : 'xmlns:$prefix="DAV:"';
    final out = StringBuffer(
      '<?xml version="1.0" encoding="utf-8"?> '
      '<${p}multistatus $ns xmlns:oc="http://owncloud.org/ns">',
    );
    for (final key in items) {
      final item = _tree[key]!;
      final href = Uri(
        pathSegments: [
          'dav',
          ...key.split('/').where((s) => s.isNotEmpty),
          if (item.folder) '',
        ],
      ).path;
      out
        ..write('<${p}response><${p}href>')
        ..write(absoluteHrefs ? '$origin/$href' : '/$href')
        ..write('</${p}href><${p}propstat><${p}prop>')
        ..write(
          item.folder
              ? '<${p}resourcetype><${p}collection/></${p}resourcetype>'
              : '<${p}resourcetype/>'
                    '<${p}getcontentlength>${item.bytes.length}'
                    '</${p}getcontentlength>',
        )
        ..write(
          '<${p}getlastmodified>${HttpDate.format(item.modified)}'
          '</${p}getlastmodified>',
        );
      final hasEtag = item.folder ? collectionEtags : etags;
      if (hasEtag) {
        out.write('<${p}getetag>${_etag(item)}</${p}getetag>');
      }
      if (fileIds) out.write('<oc:fileid>${item.id}</oc:fileid>');
      if (checksums && !item.folder) {
        out.write(
          '<oc:checksums><oc:checksum>SHA1:ABCDEF MD5:0123 '
          '</oc:checksum></oc:checksums>',
        );
      }
      // What the server lacks comes back 404, as real servers do.
      out
        ..write('</${p}prop><${p}status>HTTP/1.1 200 OK</${p}status>')
        ..write('</${p}propstat><${p}propstat><${p}prop>')
        ..write(hasEtag ? '' : '<${p}getetag/>')
        ..write(fileIds ? '' : '<oc:fileid/>')
        ..write('</${p}prop><${p}status>HTTP/1.1 404 Not Found</${p}status> ')
        ..write('</${p}propstat></${p}response>');
    }
    out.write('</${p}multistatus>');
    response
      ..statusCode = 207
      ..headers.contentType = ContentType(
        'application',
        'xml',
        charset: 'utf-8',
      )
      ..write(out);
  }

  Future<void> _get(HttpRequest request, String path) async {
    await request.drain<void>();
    final response = request.response;
    final node = _tree[path];
    if (node == null) {
      response.statusCode = 404;
      return;
    }
    if (node.folder) {
      response.statusCode = 405;
      return;
    }
    response
      ..statusCode = 200
      ..contentLength = node.bytes.length
      ..headers.set('Last-Modified', HttpDate.format(node.modified));
    if (etags) response.headers.set('ETag', _etag(node));
    if (_dropGets > 0) {
      _dropGets--;
      final socket = await response.detachSocket();
      socket.add(node.bytes.sublist(0, node.bytes.length ~/ 2));
      await socket.flush();
      socket.destroy();
      return;
    }
    response.add(node.bytes);
  }

  Future<void> _put(
    HttpRequest request,
    String path,
    Map<String, String> headers,
  ) async {
    final builder = BytesBuilder(copy: false);
    await request.forEach(builder.add);
    final bytes = builder.takeBytes();
    final response = request.response;
    final injected = _failPuts.remove(path);
    if (injected != null) {
      response.statusCode = injected;
      return;
    }
    if (!(_tree[_parent(path)]?.folder ?? false)) {
      response.statusCode = 409;
      return;
    }
    final existing = _tree[path];
    if (existing != null && existing.folder) {
      response.statusCode = 405;
      return;
    }
    if (preconditions) {
      final ifMatch = headers['if-match'];
      if (ifMatch != null &&
          (existing == null ||
              (ifMatch != '*' && ifMatch != _etag(existing)))) {
        response.statusCode = 412;
        return;
      }
      if (headers['if-none-match'] == '*' && existing != null) {
        response.statusCode = 412;
        return;
      }
    }
    putFile(path, bytes);
    final node = _tree[path]!;
    final mtime = int.tryParse(headers['x-oc-mtime'] ?? '');
    if (ocMtime && mtime != null) {
      node.modified = DateTime.fromMillisecondsSinceEpoch(
        mtime * 1000,
        isUtc: true,
      );
      response.headers.set('X-OC-MTime', 'accepted');
    }
    response.statusCode = existing == null ? 201 : 204;
    if (etags) response.headers.set('ETag', _etag(node));
  }

  Future<void> _move(
    HttpRequest request,
    String path,
    Map<String, String> headers,
  ) async {
    await request.drain<void>();
    final response = request.response;
    if (!supportMove) {
      response.statusCode = 405;
      return;
    }
    final destination = Uri.tryParse(headers['destination'] ?? '');
    final segments = destination?.pathSegments ?? const <String>[];
    if (segments.isEmpty || segments.first != 'dav') {
      response.statusCode = 400;
      return;
    }
    final target = segments.skip(1).where((s) => s.isNotEmpty).join('/');
    if (!_tree.containsKey(path)) {
      response.statusCode = 404;
      return;
    }
    if (!(_tree[_parent(target)]?.folder ?? false)) {
      response.statusCode = 409;
      return;
    }
    final overwrite = headers['overwrite'] != 'F';
    final replaced = _tree.containsKey(target);
    if (replaced && !overwrite) {
      response.statusCode = 412;
      return;
    }
    _tree.removeWhere((k, _) => k == target || k.startsWith('$target/'));
    final moved = {
      for (final key in _tree.keys.toList())
        if (key == path || key.startsWith('$path/'))
          key: '$target${key.substring(path.length)}',
    };
    for (final entry in moved.entries) {
      _tree[entry.value] = _tree.remove(entry.key)!;
    }
    _tick++;
    _touchAncestors(path);
    _touchAncestors(target);
    response.statusCode = replaced ? 204 : 201;
  }
}
