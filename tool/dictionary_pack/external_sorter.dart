// An external merge sort: the pipeline's answer to the English edition's 1.4
// million headwords and the gigabytes of entries behind them. Records are
// buffered, sorted and spilled to a run file when the shared budget is spent;
// reading them back is a k-way merge over the runs, so no stage holds more than
// its buffer plus one record per run.
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'record_io.dart';
import 'star_dict_order.dart';

/// Orders [a] before [b] by key (StarDict's order), then by value.
int compareRecords(SortRecord a, SortRecord b) {
  final byKey = compareStarDictKeys(a.key, b.key);
  return byKey != 0 ? byKey : compareBytes(a.value, b.value);
}

/// The memory every [ExternalSorter] of a run shares: when the records they
/// hold together outgrow [limitBytes], the fullest one spills to disk. One
/// budget for the 35 languages of the English pass, so a small language costs
/// nothing and the English one gets what it needs.
final class SpillBudget {
  /// A budget of [limitBytes].
  new(this.limitBytes);

  /// The records, in bytes, the sorters may hold in memory together.
  final int limitBytes;

  final List<ExternalSorter> _sorters = [];
  int _used = 0;

  void _charge(int bytes) {
    _used += bytes;
    while (_used > limitBytes) {
      ExternalSorter? fullest;
      for (final sorter in _sorters) {
        if (fullest == null || sorter._buffered > fullest._buffered) {
          fullest = sorter;
        }
      }
      if (fullest == null || fullest._buffered == 0) return;
      fullest.spill();
    }
  }
}

/// Collects records in any order and hands them back sorted by
/// [compareRecords].
final class ExternalSorter {
  /// A sorter whose runs live in a work directory, named after the sorter.
  new(this._workDir, this._name, this._budget) {
    _budget._sorters.add(this);
  }

  final Directory _workDir;
  final String _name;
  final SpillBudget _budget;
  final List<SortRecord> _records = [];
  final List<File> _runs = [];
  int _buffered = 0;

  /// How many records were added.
  int count = 0;

  /// Adds one record.
  void add(Uint8List key, Uint8List value) {
    final record = SortRecord(key, value);
    _records.add(record);
    count++;
    _buffered += record.weight;
    _budget._charge(record.weight);
  }

  /// Sorts what is in memory and writes it as a run.
  void spill() {
    if (_records.isEmpty) return;
    _records.sort(compareRecords);
    final file = File(p.join(_workDir.path, '$_name.${_runs.length}.run'));
    final writer = BufferedFileWriter(file);
    for (final record in _records) {
      writer.writeRecord(record.key, record.value);
    }
    writer.close();
    _runs.add(file);
    _budget._used -= _buffered;
    _buffered = 0;
    _records.clear();
  }

  /// The records, sorted. The sorter is spent afterwards: the runs are
  /// deleted as the last record is read, and its memory is returned.
  Iterable<SortRecord> drain() sync* {
    _budget._sorters.remove(this);
    if (_runs.isEmpty) {
      _records.sort(compareRecords);
      _budget._used -= _buffered;
      _buffered = 0;
      final records = List<SortRecord>.of(_records);
      _records.clear();
      yield* records;
      return;
    }
    spill();
    final readers = [for (final run in _runs) BufferedFileReader(run)];
    final heap = _MergeHeap();
    try {
      for (var i = 0; i < readers.length; i++) {
        final record = readers[i].readRecord();
        if (record != null) heap.add(_Head(record, i));
      }
      while (heap.isNotEmpty) {
        final head = heap.removeFirst();
        yield head.record;
        final next = readers[head.run].readRecord();
        if (next != null) heap.add(_Head(next, head.run));
      }
    } finally {
      for (final reader in readers) {
        reader.close();
      }
      for (final run in _runs) {
        if (run.existsSync()) run.deleteSync();
      }
      _runs.clear();
    }
  }
}

final class _Head {
  const new(this.record, this.run);

  final SortRecord record;
  final int run;
}

/// A binary min-heap of the runs' next records.
final class _MergeHeap {
  final List<_Head> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  bool _less(_Head a, _Head b) {
    final order = compareRecords(a.record, b.record);
    return order != 0 ? order < 0 : a.run < b.run;
  }

  void add(_Head head) {
    _items.add(head);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (!_less(_items[i], _items[parent])) break;
      final swap = _items[parent];
      _items[parent] = _items[i];
      _items[i] = swap;
      i = parent;
    }
  }

  _Head removeFirst() {
    final first = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      for (;;) {
        final left = 2 * i + 1;
        final right = left + 1;
        var smallest = i;
        if (left < _items.length && _less(_items[left], _items[smallest])) {
          smallest = left;
        }
        if (right < _items.length && _less(_items[right], _items[smallest])) {
          smallest = right;
        }
        if (smallest == i) break;
        final swap = _items[smallest];
        _items[smallest] = _items[i];
        _items[i] = swap;
        i = smallest;
      }
    }
    return first;
  }
}
