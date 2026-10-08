/// Downloading a web page to capture (#531): http and https only, a few
/// redirects, time and size limits, and nothing but HTML.
///
/// The caller runs it off the UI isolate (`Isolate.run`), as every network
/// and disk step of the capture is.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Why a page could not be downloaded.
enum PageFetchFailure {
  /// The address is not http or https.
  scheme,

  /// More redirects than [PageFetchLimits.redirects].
  redirects,

  /// No connection, or no answer, in time.
  timeout,

  /// Larger than [PageFetchLimits.bytes].
  tooLarge,

  /// Not HTML: a PDF, a picture, a download.
  notHtml,

  /// The server answered with an error.
  status,

  /// The network failed.
  network,
}

/// A page that could not be downloaded, and why.
final class PageFetchException implements Exception {
  /// The [failure], with what the server or the network said.
  const new(this.failure, [this.detail = '']);

  /// Why.
  final PageFetchFailure failure;

  /// What was said: a status code, an error.
  final String detail;

  @override
  String toString() =>
      'PageFetchException($failure${detail.isEmpty ? '' : ': $detail'})';
}

/// The limits a download is held to.
final class PageFetchLimits {
  /// The limits; the defaults are the capture's.
  const new({
    this.redirects = 5,
    this.connect = const Duration(seconds: 15),
    this.total = const Duration(seconds: 30),
    this.bytes = 10 * 1024 * 1024,
  });

  /// The most redirects followed.
  final int redirects;

  /// How long a connection may take.
  final Duration connect;

  /// How long the whole download may take.
  final Duration total;

  /// The most bytes a page may have.
  final int bytes;
}

/// A page downloaded: where it was in the end, its bytes, and its
/// `Content-Type`.
typedef FetchedPage = ({Uri url, Uint8List bytes, String? contentType});

/// The media types a page may have.
const Set<String> _htmlTypes = {'text/html', 'application/xhtml+xml'};

/// Downloads the page at [url], following up to [PageFetchLimits.redirects]
/// redirects, each of them to http or https. Throws a
/// [PageFetchException].
Future<FetchedPage> fetchPage(
  Uri url, {
  PageFetchLimits limits = const PageFetchLimits(),
}) async {
  final client = HttpClient()
    ..connectionTimeout = limits.connect
    ..userAgent = 'Niman';
  try {
    return await _follow(client, url, limits).timeout(
      limits.total,
      onTimeout: () => throw const PageFetchException(PageFetchFailure.timeout),
    );
  } on SocketException catch (error) {
    throw PageFetchException(PageFetchFailure.network, error.message);
  } on HttpException catch (error) {
    throw PageFetchException(PageFetchFailure.network, error.message);
  } on TlsException catch (error) {
    throw PageFetchException(PageFetchFailure.network, error.message);
  } on TimeoutException {
    throw const PageFetchException(PageFetchFailure.timeout);
  } finally {
    client.close(force: true);
  }
}

bool _isWeb(Uri url) => url.isScheme('http') || url.isScheme('https');

Future<FetchedPage> _follow(
  HttpClient client,
  Uri start,
  PageFetchLimits limits,
) async {
  var url = start;
  for (var hop = 0; ; hop++) {
    if (!_isWeb(url)) throw const PageFetchException(PageFetchFailure.scheme);
    final request = await client.getUrl(url);
    request
      ..followRedirects = false
      ..headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml;q=0.9,*/*;q=0.1',
      );
    final response = await request.close();
    if (response.isRedirect) {
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null) {
        throw PageFetchException(
          PageFetchFailure.status,
          '${response.statusCode} without a location',
        );
      }
      if (hop >= limits.redirects) {
        throw const PageFetchException(PageFetchFailure.redirects);
      }
      try {
        url = url.resolve(location);
      } on FormatException {
        throw PageFetchException(
          PageFetchFailure.status,
          '${response.statusCode} to $location',
        );
      }
      continue;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw PageFetchException(
        PageFetchFailure.status,
        '${response.statusCode}',
      );
    }
    final contentType = response.headers.value(HttpHeaders.contentTypeHeader);
    if (contentType != null &&
        !_htmlTypes.contains(ContentType.parse(contentType).mimeType)) {
      await response.drain<void>();
      throw PageFetchException(PageFetchFailure.notHtml, contentType);
    }
    if (response.contentLength > limits.bytes) {
      await response.drain<void>();
      throw const PageFetchException(PageFetchFailure.tooLarge);
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      bytes.add(chunk);
      if (bytes.length > limits.bytes) {
        throw const PageFetchException(PageFetchFailure.tooLarge);
      }
    }
    return (url: url, bytes: bytes.takeBytes(), contentType: contentType);
  }
}
