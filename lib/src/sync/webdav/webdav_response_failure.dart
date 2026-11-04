import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_paths.dart';

const _log = AppLogger(name: 'webdav');

/// The failure [response] says [method] on [path] met, by its status;
/// the body is drained first, and [clock] times the warning it logs.
Future<WebDavFailure> webDavResponseFailure(
  String method,
  String path,
  HttpClientResponse response,
  Stopwatch clock,
) async {
  await response.drain<void>().catchError((Object _) {});
  final status = response.statusCode;
  final text =
      '$method ${webDavShowPath(path)}: $status ${response.reasonPhrase}';
  _log.warning('$text, ${clock.elapsedMilliseconds} ms');
  return switch (status) {
    401 || 403 => WebDavAuthFailure(text, status: status),
    404 || 409 || 410 => WebDavNotFound(text, status: status),
    412 => WebDavPrecondition(text, status: status),
    408 || 423 || 425 || 429 || 500 || 502 || 503 || 504 => WebDavRetryable(
      text,
      status: status,
      retryAfter: _retryAfter(response),
    ),
    405 || 501 => WebDavUnsupported(text, status: status),
    _ => WebDavProtocolFailure(text, status: status),
  };
}

Duration? _retryAfter(HttpClientResponse response) {
  final value = response.headers.value(HttpHeaders.retryAfterHeader);
  if (value == null) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds != null) return Duration(seconds: seconds < 0 ? 0 : seconds);
  final date = webDavHttpDate(value);
  if (date == null) return null;
  final wait = date.difference(DateTime.now().toUtc());
  return wait.isNegative ? Duration.zero : wait;
}

/// [value] parsed as an HTTP date, or null when it is missing or is not one.
DateTime? webDavHttpDate(String? value) {
  if (value == null) return null;
  try {
    return HttpDate.parse(value);
  } on HttpException {
    return null;
  }
}
