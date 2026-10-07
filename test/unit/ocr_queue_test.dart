import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_job.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/ocr_page_source.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late OcrInstallation installation;
  late FakeLibrarySession library;
  final ita = ocrLanguageByCode('ita')!;
  const system = (
    name: 'libtesseract.so.5',
    source: OcrEngineSource.system,
    version: '5.5.3',
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_ocr_queue_');
    final file = ita.file(OcrQuality.fast)!;
    File(p.join(dir.path, file.fileName))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([1]);
    installation = OcrInstallation(
      directory: () async => dir.path,
      build: null,
      findInstalled: () async => system,
      probe: (_) async => '5.5.3',
    );
    await installation.load();
    library = FakeLibrarySession();
    await library.open('/fake/library', create: true);
  });

  tearDown(() async {
    installation.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  OcrPixels pixels(int page) => (
    data: TransferableTypedData.fromList([Uint8List(4)]),
    width: 1,
    height: page,
    bgra: false,
    ppi: 300,
  );

  /// A queue over a [count]-page file whose page N reads "page N".
  OcrQueue queue({
    int count = 3,
    Completer<void>? hold,
    List<String>? started,
  }) {
    final queue = OcrQueue(
      installation: installation,
      now: () => DateTime(2026, 10, 7),
      openPages: (path) async => (
        count: count,
        render: (int page) async => pixels(page),
        close: () async {},
      ),
      startRecognizer:
          ({required engine, required datapath, required languages}) async {
            started?.add('$engine $datapath $languages');
            return (
              recognize: (OcrPixels page) async {
                await hold?.future;
                return [
                  OcrLine(
                    'page ${page.height}',
                    left: 0.1,
                    top: 0.1,
                    right: 0.5,
                    bottom: 0.2,
                    paragraphStart: true,
                  ),
                ];
              },
              close: () {},
            );
          },
    );
    addTearDown(queue.dispose);
    return queue;
  }

  OcrWriter writer({List<String>? log}) => (
    root: '/fake/library',
    ops: library,
    before: () async => log?.add('before'),
    after: (sidecar) => log?.add('after $sidecar'),
  );

  Future<OcrJob> finished(OcrQueue queue) => queue.finished.first;

  test('reads every page and writes the sidecar next to the file', () async {
    final log = <String>[];
    final started = <String>[];
    await library.createFolder(parentPath: '', name: 'Contratti');
    final q = queue(started: started);
    final done = finished(q);
    final job = q.enqueue(
      path: 'Contratti/scan.pdf',
      languages: [ita],
      writer: writer(log: log),
    );
    expect(await done, same(job));
    expect(job.error, isNull);
    expect(job.phase, OcrJobPhase.done);
    expect(job.pagesTotal, 3);
    expect(job.sidecar, 'Contratti/scan.ocr.md');
    expect(job.words, 6);
    expect(started, ['libtesseract.so.5 ${p.join(dir.path, 'fast')} ita']);
    expect(log, ['before', 'after Contratti/scan.ocr.md']);
    final text = await library.readNote('Contratti/scan.ocr.md');
    expect(text, startsWith('---\nocr: "[[scan.pdf]]"\nlanguage: ita\n'));
    expect(text, contains('## p. 3\n\npage 3 <!-- ocr'));
  });

  test('a page read again is merged into the sidecar', () async {
    final q = queue();
    var done = finished(q);
    q.enqueue(path: 'scan.pdf', languages: [ita], writer: writer());
    await done;
    final first = await library.readNote('scan.ocr.md');
    await library.saveNote(
      'scan.ocr.md',
      first.replaceFirst('page 1 <!--', 'PAGE ONE <!--'),
    );
    done = finished(q);
    final again = q.enqueue(
      path: 'scan.pdf',
      languages: [ita],
      writer: writer(),
      pages: [2],
    );
    await done;
    expect(again.pagesTotal, 1);
    final merged = await library.readNote('scan.ocr.md');
    expect(merged, contains('PAGE ONE'));
    expect(merged, contains('page 2'));
  });

  test("another file's sidecar of the same stem is left alone", () async {
    await library.createNote(
      parentPath: '',
      name: 'scan.ocr',
      content: '---\nocr: "[[scan.jpg]]"\n---\n',
    );
    final q = queue(count: 1);
    final done = finished(q);
    final job = q.enqueue(path: 'scan.pdf', languages: [ita], writer: writer());
    await done;
    expect(job.sidecar, 'scan.pdf.ocr.md');
    expect(await library.readNote('scan.ocr.md'), contains('scan.jpg'));
  });

  test('pages out of range are skipped', () async {
    final q = queue(count: 2);
    final done = finished(q);
    final job = q.enqueue(
      path: 'a.pdf',
      languages: [ita],
      writer: writer(),
      pages: [0, 2, 9],
    );
    await done;
    expect(job.pagesTotal, 1);
  });

  test('cancel stops the job and writes nothing', () async {
    final hold = Completer<void>();
    final q = queue(hold: hold);
    final done = finished(q);
    final job = q.enqueue(path: 'a.pdf', languages: [ita], writer: writer());
    await Future<void>.delayed(Duration.zero);
    q.cancel(job);
    hold.complete();
    expect((await done).phase, OcrJobPhase.cancelled);
    expect(await library.find('a.ocr.md'), isNull);
  });

  test('one job at a time; the same file answers its job', () async {
    final hold = Completer<void>();
    final q = queue(count: 1, hold: hold);
    final first = q.enqueue(path: 'a.pdf', languages: [ita], writer: writer());
    final again = q.enqueue(path: 'a.pdf', languages: [ita], writer: writer());
    final second = q.enqueue(path: 'b.png', languages: [ita], writer: writer());
    expect(again, same(first));
    await Future<void>.delayed(Duration.zero);
    expect(q.running, same(first));
    expect(second.phase, OcrJobPhase.queued);
    final done = q.finished.take(2).toList();
    hold.complete();
    final order = await done;
    expect(order, [first, second]);
    expect(second.sidecar, 'b.ocr.md');
    expect(await library.readNote('b.ocr.md'), isNot(contains('## p.')));
  });
}
