import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';

void main() {
  final base = Uri.parse('http://nas:8080/webdav/My%20Notes/');

  test('reads an Apache mod_dav answer (lp1 prefixes, 404 propstat)', () {
    const body = '''
<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:" xmlns:ns0="DAV:">
<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>/webdav/My%20Notes/</D:href>
<D:propstat><D:prop>
<lp1:resourcetype><D:collection/></lp1:resourcetype>
<lp1:getlastmodified>Tue, 15 Sep 2026 10:00:00 GMT</lp1:getlastmodified>
<lp1:getetag>"1000-5f0"</lp1:getetag>
</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat>
</D:response>
<D:response xmlns:lp1="DAV:">
<D:href>/webdav/My%20Notes/Plan%20%C3%A8.md</D:href>
<D:propstat><D:prop>
<lp1:resourcetype/>
<lp1:getcontentlength>42</lp1:getcontentlength>
<lp1:getlastmodified>Tue, 15 Sep 2026 10:01:02 GMT</lp1:getlastmodified>
<lp1:getetag>"2a-5f1"</lp1:getetag>
</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat>
<D:propstat><D:prop><ns1:fileid xmlns:ns1="http://owncloud.org/ns"/>
<D:getetag>"ignored-in-404"</D:getetag>
</D:prop><D:status>HTTP/1.1 404 Not Found</D:status></D:propstat>
</D:response>
</D:multistatus>''';
    final items = parseMultistatus(body, base);
    expect(items, hasLength(2));
    expect(items[0].path, '');
    expect(items[0].isCollection, isTrue);
    expect(items[1].path, 'Plan è.md');
    expect(items[1].name, 'Plan è.md');
    expect(items[1].isCollection, isFalse);
    expect(items[1].size, 42);
    expect(items[1].etag, '"2a-5f1"');
    expect(items[1].modified, DateTime.utc(2026, 9, 15, 10, 1, 2));
    expect(items[1].fileId, isNull);
  });

  test('reads an nginx-style answer: no ETags, default namespace, '
      'absolute URL hrefs, unencoded characters', () {
    const body = '''
<?xml version="1.0" encoding="utf-8" ?>
<multistatus xmlns="DAV:">
<response><href>http://nas:8080/webdav/My Notes/Inbox/</href>
<propstat><prop><resourcetype><collection/></resourcetype>
<getlastmodified>Tue, 15 Sep 2026 09:00:00 GMT</getlastmodified></prop>
<status>HTTP/1.1 200 OK</status></propstat></response>
<response><href>http://nas:8080/webdav/My%20Notes/Inbox/a.md</href>
<propstat><prop><resourcetype></resourcetype>
<getcontentlength>7</getcontentlength></prop>
<status>HTTP/1.1 200 OK</status></propstat></response>
</multistatus>''';
    final items = parseMultistatus(body, base);
    expect(items.map((i) => i.path), ['Inbox', 'Inbox/a.md']);
    expect(items[0].isCollection, isTrue);
    expect(items[1].etag, isNull);
    expect(items[1].size, 7);
    expect(items[1].modified, isNull);
  });

  test('reads Nextcloud extras: oc:fileid and oc:checksums', () {
    const body = '''
<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
<d:response><d:href>/webdav/My%20Notes/a.md</d:href>
<d:propstat><d:prop><d:resourcetype/><d:getetag>&quot;abc&quot;</d:getetag>
<oc:fileid>00001234</oc:fileid>
<oc:checksums><oc:checksum>SHA1:ABCD MD5:EF01 ADLER32:99</oc:checksum></oc:checksums>
</d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''';
    final item = parseMultistatus(body, base).single;
    expect(item.etag, '"abc"');
    expect(item.fileId, '00001234');
    expect(item.checksums, {'sha1': 'abcd', 'md5': 'ef01', 'adler32': '99'});
  });

  test('skips hrefs outside the destination and reports them', () {
    const body = '''
<d:multistatus xmlns:d="DAV:">
<d:response><d:href>/other/x.md</d:href><d:propstat><d:prop/>
<d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
<d:response><d:href>/webdav/My%zzNotes/y.md</d:href></d:response>
<d:response><d:href>/webdav/My%20Notes/z.md</d:href></d:response>
</d:multistatus>''';
    final skipped = <String>[];
    final items = parseMultistatus(body, base, onSkipped: skipped.add);
    expect(items.map((i) => i.path), ['z.md']);
    expect(skipped, ['/other/x.md', '/webdav/My%zzNotes/y.md']);
  });

  test('an unparsable body or a non-multistatus root is a protocol '
      'failure', () {
    expect(
      () => parseMultistatus('<html><body>login', base),
      throwsA(isA<WebDavProtocolFailure>()),
    );
    expect(
      () => parseMultistatus('<html xmlns="x"/>', base),
      throwsA(isA<WebDavProtocolFailure>()),
    );
  });

  test('ISO dates are accepted when a server sends them', () {
    const body = '''
<d:multistatus xmlns:d="DAV:"><d:response><d:href>/webdav/My%20Notes/a</d:href>
<d:propstat><d:prop><d:getlastmodified>2026-09-15T10:00:00Z</d:getlastmodified>
</d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>
</d:multistatus>''';
    expect(
      parseMultistatus(body, base).single.modified,
      DateTime.utc(2026, 9, 15, 10),
    );
  });
}
