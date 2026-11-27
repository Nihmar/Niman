// Writes a pack from the sorted entries: one merge, so a headword's entries
// from every part of speech meet, and the English edition's forms (for a pack
// built from its own edition) are met in the same walk.
//
// Nothing here holds the language: the entries arrive from an external sort,
// the forms leave for another, and the only per-headword memory is the group
// being written.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'dictzip_writer.dart';
import 'entry_html.dart';
import 'entry_records.dart';
import 'external_sorter.dart';
import 'pack_collectors.dart';
import 'pack_ifo.dart';
import 'pack_languages.dart';
import 'pack_report.dart';
import 'record_io.dart';
import 'source_entry.dart';
import 'star_dict_order.dart';

/// What [writePack] is given besides the entries.
typedef PackSetup = ({
  PackLanguage language,
  String definitions,
  String source,
  Directory outDir,
  Directory workDir,
  SpillBudget budget,
  String date,
  bool dictzip,
});

/// Writes the pack of [setup] into `setup.outDir` and returns its report.
/// [facts] is what the English edition says of the language, sorted by
/// lemma, for an own edition's pack; [skipped] what the parsers left out.
PackReport writePack(
  PackSetup setup,
  EntryCollector collector, {
  Iterable<SortRecord>? facts,
  Map<String, int> skipped = const {},
}) {
  final id = setup.language.id;
  setup.outDir.createSync(recursive: true);
  File file(String extension) =>
      File(p.join(setup.outDir.path, '$id.$extension'));
  final dict = BufferedFileWriter(file('dict'));
  final idx = BufferedFileWriter(file('idx'));
  final keys = File(p.join(setup.workDir.path, '$id.keys'));
  final keyWriter = BufferedFileWriter(keys);
  final syn = ExternalSorter(setup.workDir, '$id.syn', setup.budget);
  final cursor = facts == null ? null : _FactCursor(facts);

  var headwords = 0;
  var inflectionHeadwords = 0;
  var senses = 0;
  var forms = 0;
  var formsFromEnglish = 0;
  var sharedHeadwords = 0;
  var sharedOwnSenses = 0;
  var sharedEnglishSenses = 0;
  final empty = Uint8List(0);

  for (final group in _groups(collector.sorter.drain())) {
    final headword = utf8.decode(group.key);
    final sections = <String>[];
    final spans = <String, (String, String)>{};
    var groupSenses = 0;
    for (final record in group.records) {
      final part = decodeEntryPart(record.value);
      sections.add(part.section);
      groupSenses += part.senses;
      for (final line in part.forms) {
        final tab = line.indexOf('\t');
        spans.putIfAbsent(
          line,
          () => (line.substring(0, tab), line.substring(tab + 1)),
        );
      }
    }
    if (cursor != null) {
      final known = {for (final (_, form) in spans.values) form};
      var english = 0;
      var hasEnglishHeadword = false;
      for (final fact in cursor.factsFor(group.key)) {
        switch (fact) {
          case EnglishHeadword(:final senses):
            hasEnglishHeadword = true;
            english += senses;
          case EnglishForm(:final form, :final tags):
            if (form != headword && known.add(form)) {
              spans['$tags\t$form'] = (tags, form);
              formsFromEnglish++;
            }
        }
      }
      if (hasEnglishHeadword) {
        sharedHeadwords++;
        sharedOwnSenses += groupSenses;
        sharedEnglishSenses += english;
      }
    }

    final html = utf8.encode(
      renderEntry(headword, sections, [
        for (final (tags, form) in spans.values)
          renderForm(form, tags.isEmpty ? const [] : tags.split(' ')),
      ]),
    );
    if (dict.position + html.length > 0xffffffff) {
      throw StateError('$id.dict outgrows 32-bit offsets at "$headword".');
    }
    idx
      ..write(group.key)
      ..write(const [0])
      ..writeUint32(dict.position)
      ..writeUint32(html.length);
    dict.write(html);
    keyWriter.writeRecord(group.key, empty);
    final index = Uint8List(4);
    ByteData.sublistView(index).setUint32(0, headwords);
    for (final form in {for (final (_, form) in spans.values) form}) {
      final bytes = utf8.encode(form);
      if (form != headword && bytes.length <= maxHeadwordBytes) {
        syn.add(Uint8List.fromList(bytes), index);
      }
    }
    headwords++;
    senses += groupSenses;
    forms += spans.length;
    if (sections.any((s) => s.contains('class="form-of"'))) {
      inflectionHeadwords++;
    }
  }
  cursor?.finish();
  dict.close();
  idx.close();
  keyWriter.close();

  final synRecords = _writeSyn(syn, keys, file('syn'));
  keys.deleteSync();
  final idxSize = file('idx').lengthSync();
  writeIfo(file('ifo'), (
    language: setup.language,
    definitions: setup.definitions,
    source: setup.source,
    wordCount: headwords,
    synWordCount: synRecords,
    idxFileSize: idxSize,
    date: setup.date,
  ));
  final sizes = <String, int>{
    'ifo': file('ifo').lengthSync(),
    'idx': idxSize,
    'syn': file('syn').lengthSync(),
    'dict': file('dict').lengthSync(),
  };
  if (setup.dictzip) {
    final packed = file('dict.dz');
    writeDictzip(file('dict'), packed, name: '$id.dict');
    file('dict').deleteSync();
    sizes['dict.dz'] = packed.lengthSync();
  }
  return PackReport(
    id: id,
    languages: setup.language.languages,
    definitions: setup.definitions,
    source: setup.source,
    headwords: headwords,
    inflectionHeadwords: inflectionHeadwords,
    sourceEntries: collector.entries,
    senses: senses,
    forms: forms,
    synRecords: synRecords,
    skipped: skipped,
    fileSizes: sizes,
    comparison: cursor == null
        ? null
        : EnglishComparison(
            englishHeadwords: cursor.headwords,
            englishSenses: cursor.senses,
            sharedHeadwords: sharedHeadwords,
            sharedOwnSenses: sharedOwnSenses,
            sharedEnglishSenses: sharedEnglishSenses,
            formsFromEnglish: formsFromEnglish,
          ),
  );
}

/// Writes the `.syn` from the sorted form records, leaving out the forms that
/// are headwords themselves (their own entry says what they are a form of),
/// and returns how many records it holds. [keys] lists the headwords in order.
int _writeSyn(ExternalSorter syn, File keys, File target) {
  final out = BufferedFileWriter(target);
  final headwords = BufferedFileReader(keys);
  var head = headwords.readRecord();
  SortRecord? previous;
  var count = 0;
  for (final record in syn.drain()) {
    if (previous != null && compareRecords(previous, record) == 0) {
      continue;
    }
    previous = record;
    while (head != null && compareStarDictKeys(head.key, record.key) < 0) {
      head = headwords.readRecord();
    }
    if (head != null && compareStarDictKeys(head.key, record.key) == 0) {
      continue;
    }
    out
      ..write(record.key)
      ..write(const [0])
      ..write(record.value);
    count++;
  }
  headwords.close();
  out.close();
  return count;
}

/// The records of one headword.
typedef _Group = ({Uint8List key, List<SortRecord> records});

Iterable<_Group> _groups(Iterable<SortRecord> sorted) sync* {
  Uint8List? key;
  var records = <SortRecord>[];
  for (final record in sorted) {
    if (key != null && compareBytes(key, record.key) != 0) {
      yield (key: key, records: records);
      records = [];
    }
    key = record.key;
    records.add(record);
  }
  if (key != null) yield (key: key, records: records);
}

/// The English edition's facts, read forward in step with the entries.
final class _FactCursor {
  new(Iterable<SortRecord> records) : _iterator = records.iterator {
    _advance();
  }

  final Iterator<SortRecord> _iterator;
  SortRecord? _head;
  Uint8List? _lastHeadword;

  /// The distinct lemmas the English edition has an entry for, and the senses
  /// of them: complete once [finish] has run.
  int headwords = 0;
  int senses = 0;

  void _advance() => _head = _iterator.moveNext() ? _iterator.current : null;

  /// The facts of exactly [key]. The facts of keys before it are passed over
  /// (and counted), since the entries arrive in the same order.
  List<EnglishFact> factsFor(Uint8List key) {
    final facts = <EnglishFact>[];
    for (var head = _head; head != null; head = _head) {
      final order = compareStarDictKeys(head.key, key);
      if (order > 0) break;
      final fact = EnglishFact.decode(head.value);
      if (fact is EnglishHeadword) {
        final last = _lastHeadword;
        if (last == null || compareBytes(last, head.key) != 0) headwords++;
        _lastHeadword = head.key;
        senses += fact.senses;
      }
      if (order == 0) facts.add(fact);
      _advance();
    }
    return facts;
  }

  /// Counts what the entries left behind.
  void finish() {
    for (var head = _head; head != null; head = _head) {
      factsFor(head.key);
    }
  }
}
