/// A [File] that does the real work and writes down the steps a write's
/// durability depends on (#1058): which temp file was flushed to storage, and
/// when it was renamed. Installed with `IOOverrides.runZoned`, so the code
/// under test is the production code, untouched.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The steps recorded, in order: `flush <name>`, `rename <name> -> <name>`.
typedef FileLog = List<String>;

/// Runs [body] with every `File(path)` it makes a [RecordingFile] over the
/// real one, writing its steps to [log].
Future<T> recordingFiles<T>(FileLog log, Future<T> Function() body) =>
    IOOverrides.runZoned(
      body,
      createFile: (path) => RecordingFile(Zone.root.run(() => File(path)), log),
    );

/// A [File] delegating to a real one; only what the write paths use is
/// implemented, and anything else throws, loudly.
final class RecordingFile implements File {
  /// Wraps [_real], logging to [_log].
  new(this._real, this._log);

  final File _real;
  final FileLog _log;

  @override
  String get path => _real.path;

  @override
  Directory get parent => _real.parent;

  @override
  bool existsSync() => _real.existsSync();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      _real.delete(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) =>
      _real.deleteSync(recursive: recursive);

  @override
  FileStat statSync() => _real.statSync();

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    // The write-and-flush in one call is a flush too.
    if (flush) _log.add('flush ${p.basename(path)}');
    await _real.writeAsBytes(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) => _real.openWrite(mode: mode, encoding: encoding);

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      _RecordingHandle(await _real.open(mode: mode), _log, p.basename(path));

  @override
  Future<File> rename(String newPath) {
    _log.add('rename ${p.basename(path)} -> ${p.basename(newPath)}');
    return _real.rename(newPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('RecordingFile.${invocation.memberName}');
}

final class _RecordingHandle implements RandomAccessFile {
  new(this._real, this._log, this._name);

  final RandomAccessFile _real;
  final FileLog _log;
  final String _name;

  @override
  Future<RandomAccessFile> flush() async {
    _log.add('flush $_name');
    await _real.flush();
    return this;
  }

  @override
  Future<void> close() => _real.close();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('RandomAccessFile.${invocation.memberName}');
}
