import 'package:whisper_ggml/whisper_ggml.dart';

/// One speech-to-text model the app offers (docs/records/transcription.md).
///
/// A thin description over the package's [WhisperModel]: what the model
/// page lists, how big the download is, and where it goes on disk. Only
/// the multilingual models are offered; the `.en` and diarization
/// variants stay out of the list.
final class TranscriptionModel {
  /// Describes [whisper], whose ggml file is [bytes] long.
  const new(
    this.whisper, {
    required this.bytes,
    this.onPhones = true,
    this.slowOnPhones = false,
  });

  /// The package model this entry stands for.
  final WhisperModel whisper;

  /// The size of the published ggml file, for the list and the storage
  /// summary before a download reports its own `Content-Length`.
  final int bytes;

  /// Whether Android offers it; large-v3 needs more memory than a phone
  /// can spare.
  final bool onPhones;

  /// Whether a phone gets a "slow" warning next to it.
  final bool slowOnPhones;

  /// The stable id stored in the settings file (`tiny`, `large-v3`, …).
  String get id => whisper.modelName;

  /// The file name the package loads the model from. `whisper_ggml`
  /// resolves `<model dir>/ggml-<name>.bin` itself (`WhisperController.
  /// getPath`), so downloads have to land exactly there.
  String get fileName => 'ggml-${whisper.modelName}.bin';

  /// Where the weights are published.
  Uri get uri => whisper.modelUri;

  @override
  String toString() => id;
}

/// Every model the app knows, smallest first. Sizes are the published
/// ggml files (whisper.cpp on Hugging Face).
const List<TranscriptionModel> transcriptionModels = [
  TranscriptionModel(WhisperModel.tiny, bytes: 77691713),
  TranscriptionModel(WhisperModel.base, bytes: 147951465),
  TranscriptionModel(WhisperModel.small, bytes: 487601967),
  TranscriptionModel(
    WhisperModel.medium,
    bytes: 1533763059,
    slowOnPhones: true,
  ),
  TranscriptionModel(WhisperModel.large, bytes: 3095033483, onPhones: false),
];

/// The models a device offers: all of them on desktop, all but those a
/// phone cannot run on Android.
List<TranscriptionModel> offeredTranscriptionModels({required bool phone}) => [
  for (final model in transcriptionModels)
    if (!phone || model.onPhones) model,
];

/// The model with [id], or null for an unknown or missing id.
TranscriptionModel? transcriptionModelById(String? id) {
  for (final model in transcriptionModels) {
    if (model.id == id) return model;
  }
  return null;
}
