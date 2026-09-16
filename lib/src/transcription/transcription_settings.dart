import 'package:meta/meta.dart';
import 'package:niman/src/core/language.dart';

/// The transcription choices of this installation: which model to use and
/// which language the recordings are in.
///
/// Stored as `transcription.json` next to the models
/// (`TranscriptionSettingsStore`) rather than in `AppDatabase`: they
/// belong to the downloaded models on this device, and keeping them out
/// of the schema leaves the migration chain to the sync work.
@immutable
final class TranscriptionSettings {
  /// Creates settings using [modelId] in [language].
  const new({this.modelId, this.language = followApp});

  /// Reads [json], falling back to the defaults for anything missing or
  /// of the wrong type, so a hand-edited or truncated file never blocks
  /// the page.
  factory fromJson(Object? json) {
    if (json is! Map) return const TranscriptionSettings();
    final model = json['model'];
    final language = json['language'];
    return TranscriptionSettings(
      modelId: model is String && model.isNotEmpty ? model : null,
      language: language is String && language.isNotEmpty
          ? language
          : followApp,
    );
  }

  /// [language] value: transcribe in the app's own language.
  static const String followApp = 'app';

  /// [language] value: let whisper detect the language.
  static const String detect = 'auto';

  /// The default model's id, or null before any model is chosen.
  final String? modelId;

  /// [followApp], [detect], or an [AppLanguage.id].
  final String language;

  /// These settings with [modelId] replaced (null clears it).
  TranscriptionSettings withModel(String? modelId) =>
      TranscriptionSettings(modelId: modelId, language: language);

  /// These settings with [language] replaced.
  TranscriptionSettings withLanguage(String language) =>
      TranscriptionSettings(modelId: modelId, language: language);

  /// The language code whisper is given, with [app] as the language the
  /// app speaks.
  ///
  /// Whisper takes ISO 639-1 codes; the one app language whose id is not
  /// one of them is Norwegian Bokmål (`nb`), which whisper knows as `no`.
  String whisperLanguage(AppLanguage app) {
    final id = switch (language) {
      followApp => app.id,
      _ => language,
    };
    return switch (id) {
      'nb' => 'no',
      'system' => 'auto',
      _ => id,
    };
  }

  /// The JSON object written to disk.
  Map<String, Object?> toJson() => {'model': modelId, 'language': language};

  @override
  bool operator ==(Object other) =>
      other is TranscriptionSettings &&
      other.modelId == modelId &&
      other.language == language;

  @override
  int get hashCode => Object.hash(modelId, language);

  @override
  String toString() => 'model ${modelId ?? '-'}, language $language';
}
