import 'package:meta/meta.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/ocr/ocr_language.dart';

/// The text recognition choices of this installation: the models'
/// quality, the default language and the one recognized "Also".
///
/// Stored as `ocr.json` next to the downloaded languages, like the
/// transcription's settings: they belong to the data on this device.
@immutable
final class OcrSettings {
  /// Settings reading [language] (null: the app's) and [also], with
  /// [quality] models.
  const new({this.quality = OcrQuality.fast, this.language, this.also});

  /// Reads [json], falling back to the defaults for anything missing or
  /// of the wrong type.
  factory fromJson(Object? json) {
    if (json is! Map) return const OcrSettings();
    String? code(Object? value) =>
        value is String && ocrLanguageByCode(value) != null ? value : null;
    return OcrSettings(
      quality:
          OcrQuality.values.asNameMap()[json['quality']] ?? OcrQuality.fast,
      language: code(json['language']),
      also: code(json['also']),
    );
  }

  /// The models' quality.
  final OcrQuality quality;

  /// The default language's code; null follows the app's language.
  final String? language;

  /// The second language read with it, or null.
  final String? also;

  /// The default language: the chosen one, else the app's when the OCR
  /// knows it, else English.
  OcrLanguage defaultLanguage(AppLanguage app) =>
      ocrLanguageByCode(language) ??
      ocrLanguageByCode(ocrCodeOfAppLanguage(app.id)) ??
      ocrLanguageByCode('eng')!;

  /// The second language, when one is set and differs from the first.
  OcrLanguage? alsoLanguage(AppLanguage app) {
    final second = ocrLanguageByCode(also);
    return second == null || second == defaultLanguage(app) ? null : second;
  }

  /// These settings with [quality].
  OcrSettings withQuality(OcrQuality quality) =>
      OcrSettings(quality: quality, language: language, also: also);

  /// These settings with [language] as the default.
  OcrSettings withLanguage(String language) =>
      OcrSettings(quality: quality, language: language, also: also);

  /// These settings with [also] (null: none).
  OcrSettings withAlso(String? also) =>
      OcrSettings(quality: quality, language: language, also: also);

  /// The JSON object written to disk.
  Map<String, Object?> toJson() => {
    'quality': quality.name,
    'language': language,
    'also': also,
  };

  @override
  bool operator ==(Object other) =>
      other is OcrSettings &&
      other.quality == quality &&
      other.language == language &&
      other.also == also;

  @override
  int get hashCode => Object.hash(quality, language, also);

  @override
  String toString() =>
      '${quality.name}, language ${language ?? 'app'}, also ${also ?? '-'}';
}

/// The OCR language matching the app language [id] (ISO 639-1), or null.
String? ocrCodeOfAppLanguage(String id) => switch (id) {
  'en' => 'eng',
  'fr' => 'fra',
  'de' => 'deu',
  'es' => 'spa',
  'pt' => 'por',
  'zh' => 'chi_sim',
  'ja' => 'jpn',
  'hi' => 'hin',
  'it' => 'ita',
  'nl' => 'nld',
  'sv' => 'swe',
  'nb' => 'nor',
  'da' => 'dan',
  'eu' => 'eus',
  'ca' => 'cat',
  'gl' => 'glg',
  'pl' => 'pol',
  'cs' => 'ces',
  'fi' => 'fin',
  'ro' => 'ron',
  'hu' => 'hun',
  'hr' => 'hrv',
  'sk' => 'slk',
  'sl' => 'slv',
  'et' => 'est',
  'lv' => 'lav',
  'lt' => 'lit',
  'bg' => 'bul',
  'uk' => 'ukr',
  'be' => 'bel',
  'sr' => 'srp',
  'bs' => 'bos',
  'mk' => 'mkd',
  'sq' => 'sqi',
  'el' => 'ell',
  'is' => 'isl',
  'tr' => 'tur',
  _ => null,
};
