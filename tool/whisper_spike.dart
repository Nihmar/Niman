// Phase 0 spike for on-device transcription with whisper_ggml.
//
// Measures, on the device it runs on, every step the "Trascrivi" feature
// will go through, and logs each one under [whisper-spike]:
//   - the model download (bytes, time, throughput),
//   - the package's own audio conversion (ffmpeg_kit on Android, `ffmpeg`
//     from PATH on desktop),
//   - a cold transcription (model load + inference) and a warm one
//     (model kept loaded), so load time = cold - warm,
//   - progress callbacks, real-time factor, resident memory,
//   - the stray `<audio>.wav` the package writes next to its input.
//
// Desktop, unattended (exits when done):
//   flutter run -d windows --release -t tool/whisper_spike.dart
//     --dart-define=SPIKE_AUDIO=C:\path\clip.wav
//     --dart-define=SPIKE_MODELS=tiny,base --dart-define=SPIKE_LANG=it
//
// Phone: flutter run --release -t tool/whisper_spike.dart, then record a
// clip (same RecordConfig as the app) or pick a file, choose the models
// and press "Avvia". "Copia log" puts the whole log on the clipboard.

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/wav_duration.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart' as record;
import 'package:whisper_ggml/whisper_ggml.dart';

const _audioArg = String.fromEnvironment('SPIKE_AUDIO');
const _modelsArg = String.fromEnvironment(
  'SPIKE_MODELS',
  defaultValue: 'tiny,base',
);
const _langArg = String.fromEnvironment('SPIKE_LANG', defaultValue: 'it');

const _log = AppLogger(name: 'whisper-spike');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _SpikeApp());
}

class _SpikeApp extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const _SpikePage(),
    );
  }
}

class _SpikePage extends StatefulWidget {
  const new();

  @override
  State<_SpikePage> createState() => _SpikePageState();
}

class _SpikePageState extends State<_SpikePage> {
  final _lines = <String>[];
  final _recorder = record.AudioRecorder();
  final _selected = <WhisperModel>{};
  String? _audio;
  bool _recording = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    for (final name in _modelsArg.split(',')) {
      final model = WhisperModel.values.where((m) => m.name == name.trim());
      _selected.addAll(model);
    }
    if (_audioArg.isNotEmpty) {
      _audio = _audioArg;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _run();
        exit(0);
      });
    }
  }

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    super.dispose();
  }

  void _say(String line) {
    _log.info(line);
    debugPrint('[whisper-spike] $line');
    if (mounted) setState(() => _lines.add(line));
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _audio = path;
      });
      _say('recorded: $path');
      return;
    }
    if (!await _recorder.hasPermission()) {
      _say('microphone permission denied');
      return;
    }
    final dir = await Directory.systemTemp.createTemp('whisper_spike_rec_');
    final path = p.join(dir.path, 'clip.wav');
    // The app's RecordConfig (record_audio_recorder.dart): plugin defaults.
    await _recorder.start(
      const record.RecordConfig(encoder: record.AudioEncoder.wav),
      path: path,
    );
    setState(() => _recording = true);
  }

  Future<void> _pick() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    final path = result.isEmpty ? null : result.first.path;
    if (path != null) setState(() => _audio = path);
  }

  Future<void> _run() async {
    final audio = _audio;
    if (audio == null || _running) return;
    setState(() => _running = true);
    try {
      await _Spike(_say).run(audio, _selected.toList(), _langArg);
    } on Object catch (e, st) {
      _say('FAILED: $e\n$st');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('whisper_ggml spike')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _running ? null : _toggleRecording,
                  child: Text(_recording ? 'Stop' : 'Registra'),
                ),
                FilledButton.tonal(
                  onPressed: _running || _recording ? null : _pick,
                  child: const Text('Scegli file'),
                ),
                FilledButton(
                  onPressed: _running || _recording || _audio == null
                      ? null
                      : _run,
                  child: Text(_running ? 'In corso…' : 'Avvia'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _lines.join('\n'))),
                  child: const Text('Copia log'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final model in const [
                  WhisperModel.tiny,
                  WhisperModel.base,
                  WhisperModel.small,
                  WhisperModel.medium,
                ])
                  FilterChip(
                    label: Text(model.modelName),
                    selected: _selected.contains(model),
                    onSelected: _running
                        ? null
                        : (on) => setState(
                            () => on
                                ? _selected.add(model)
                                : _selected.remove(model),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Audio: ${_audio ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),
            Expanded(
              child: SelectionArea(
                child: ListView.builder(
                  itemCount: _lines.length,
                  itemBuilder: (_, i) => Text(
                    _lines[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The measurements, independent of the page.
class _Spike {
  new(this.say);

  final void Function(String) say;
  final _controller = WhisperController();

  String _mb(num bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
  String _rss() =>
      'rss ${_mb(ProcessInfo.currentRss)} MB, '
      'max ${_mb(ProcessInfo.maxRss)} MB';

  Future<void> run(
    String audioPath,
    List<WhisperModel> models,
    String lang,
  ) async {
    final total = Stopwatch()..start();
    say(
      'env: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}, '
      '${Platform.numberOfProcessors} cpus, ${_rss()}',
    );
    say('model dir: ${await WhisperController.getModelDir()}');

    final format = await _describeWav(audioPath);
    say('audio: $audioPath, $format');

    // Every run works on a private copy: the package writes
    // `<input>.wav` next to its input, which must never be the library.
    final work = await Directory.systemTemp.createTemp('whisper_spike_');
    final copy = p.join(work.path, 'input${p.extension(audioPath)}');
    await File(audioPath).copy(copy);

    await _probeConversion(copy);

    for (final model in models) {
      say('--- model ${model.modelName} ---');
      await _ensureModel(model);
      final cold = await _transcribe(
        model,
        copy,
        lang,
        'cold',
        format.duration,
      );
      final warm = await _transcribe(
        model,
        copy,
        lang,
        'warm',
        format.duration,
      );
      if (cold != null && warm != null) {
        say('model ${model.modelName}: load ≈ ${cold - warm} ms (cold - warm)');
      }
      final release = Stopwatch()..start();
      await _controller.releaseModel();
      say('releaseModel: ${release.elapsedMilliseconds} ms, ${_rss()}');
    }

    final stray = File('$copy.wav');
    say(
      'stray converted file next to the input: '
      '${stray.existsSync() ? 'YES (${stray.lengthSync()} b)' : 'no'}',
    );
    await work.delete(recursive: true);
    say('spike done in ${total.elapsedMilliseconds} ms');
  }

  Future<_WavFormat> _describeWav(String path) async {
    final file = File(path);
    final length = await file.length();
    final raf = await file.open();
    try {
      final header = await raf.read(wavHeaderProbeBytes);
      return _WavFormat.parse(header, length);
    } finally {
      await raf.close();
    }
  }

  Future<void> _probeConversion(String input) async {
    final out = File(p.join(p.dirname(input), 'probe16k.wav'));
    final clock = Stopwatch()..start();
    final converted = await WhisperAudioConvert(
      audioInput: File(input),
      audioOutput: out,
    ).convert();
    if (converted == null) {
      say(
        'package conversion: none after ${clock.elapsedMilliseconds} ms '
        '(ffmpeg unavailable or failed)',
      );
      return;
    }
    final format = await _describeWav(converted.path);
    say('package conversion: ${clock.elapsedMilliseconds} ms -> $format');
    await converted.delete();
  }

  Future<void> _ensureModel(WhisperModel model) async {
    final path = await _controller.getPath(model);
    final file = File(path);
    if (file.existsSync()) {
      say(
        'model ${model.modelName}: already on disk, '
        '${_mb(file.lengthSync())} MB',
      );
      return;
    }
    // Our own streaming download (the package's downloadModel buffers the
    // whole file in memory and reports no progress).
    final clock = Stopwatch()..start();
    final client = HttpClient();
    final part = File('$path.part');
    try {
      final response = await (await client.getUrl(model.modelUri)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: model.modelUri);
      }
      final expected = response.contentLength;
      say(
        'download ${model.modelName}: ${model.modelUri} '
        '(${expected > 0 ? '${_mb(expected)} MB' : 'size unknown'}), '
        'headers after ${clock.elapsedMilliseconds} ms',
      );
      final sink = part.openWrite();
      var received = 0;
      var nextReport = 10;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (expected > 0 && received * 100 ~/ expected >= nextReport) {
          say(
            'download ${model.modelName}: $nextReport% ${_mb(received)} MB '
            'at ${clock.elapsedMilliseconds} ms',
          );
          nextReport += 10;
        }
      }
      await sink.close();
      await part.rename(path);
      final seconds = clock.elapsedMilliseconds / 1000;
      final speed = (received / (1024 * 1024) / seconds).toStringAsFixed(1);
      say(
        'download ${model.modelName}: ${_mb(received)} MB in '
        '${clock.elapsedMilliseconds} ms ($speed MB/s)',
      );
    } finally {
      client.close();
    }
  }

  /// Returns the wall time in ms, or null when the package gave no result.
  Future<int?> _transcribe(
    WhisperModel model,
    String audio,
    String lang,
    String label,
    Duration? audioLength,
  ) async {
    var callbacks = 0;
    int? firstProgressMs;
    final clock = Stopwatch()..start();
    say('transcribe ${model.modelName} $label: start, ${_rss()}');
    final result = await _controller.transcribe(
      model: model,
      audioPath: audio,
      lang: lang,
      suppressNonSpeechTokens: true,
      keepModelLoaded: true,
      onProgress: (percent) {
        callbacks++;
        firstProgressMs ??= clock.elapsedMilliseconds;
      },
    );
    final wall = clock.elapsedMilliseconds;
    if (result == null) {
      say(
        'transcribe ${model.modelName} $label: NO RESULT after $wall ms '
        '(see the package error above)',
      );
      return null;
    }
    final text = result.transcription.text.trim();
    final rtf = audioLength == null || audioLength == Duration.zero
        ? 'n/a'
        : (wall / audioLength.inMilliseconds).toStringAsFixed(2);
    say(
      'transcribe ${model.modelName} $label: wall $wall ms, '
      'package ${result.time.inMilliseconds} ms, rtf $rtf, '
      '$callbacks progress callbacks '
      '(first at ${firstProgressMs ?? '-'} ms), '
      '${text.length} chars, ${_rss()}',
    );
    say('text ${model.modelName} $label: $text');
    return wall;
  }
}

class _WavFormat {
  const new(
    this.sampleRate,
    this.channels,
    this.bits,
    this.duration,
    this.bytes,
  );

  factory parse(Uint8List header, int length) {
    final data = ByteData.sublistView(header);
    var offset = 12;
    while (header.length >= 12 && offset + 8 <= header.length) {
      final id = String.fromCharCodes(header.sublist(offset, offset + 4));
      final size = data.getUint32(offset + 4, Endian.little);
      if (id == 'fmt ' && offset + 24 <= header.length) {
        return _WavFormat(
          data.getUint32(offset + 12, Endian.little),
          data.getUint16(offset + 10, Endian.little),
          data.getUint16(offset + 22, Endian.little),
          wavDurationOf(header, length),
          length,
        );
      }
      offset += 8 + size + (size.isOdd ? 1 : 0);
    }
    return _WavFormat(null, null, null, null, length);
  }

  final int? sampleRate;
  final int? channels;
  final int? bits;
  final Duration? duration;
  final int bytes;

  @override
  String toString() => sampleRate == null
      ? 'not a WAV, $bytes b'
      : '$sampleRate Hz, $channels ch, $bits bit, '
            '${duration?.inMilliseconds ?? '?'} ms, $bytes b';
}
