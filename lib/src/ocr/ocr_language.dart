import 'package:meta/meta.dart';
import 'package:niman/src/core/download/downloadable.dart';
import 'package:niman/src/ocr/ocr_language_catalog.dart';

/// The trained models a language comes in: tessdata_fast (1–4 MB, quick
/// on a phone) or tessdata_best (10–15 MB, better on hard scans, slower).
enum OcrQuality {
  /// tessdata_fast.
  fast,

  /// tessdata_best.
  best,
}

/// One published model file: its size and digest.
typedef OcrModelFile = ({int bytes, String sha256});

/// One language the OCR can read, from the generated catalog
/// ([ocrLanguages]).
final class OcrLanguage {
  /// The language [code] (Tesseract's: `ita`, `chi_sim`, …), named
  /// [native] in itself and [english] for search, with its [fast] and
  /// [best] models where published.
  const new(
    this.code, {
    required this.native,
    required this.english,
    required this.fast,
    required this.best,
  });

  /// Tesseract's code, what `Init` takes (`ita+eng`).
  final String code;

  /// The name in the language itself: needs no translation.
  final String native;

  /// The English name, matched by search too.
  final String english;

  /// The tessdata_fast model, when published.
  final OcrModelFile? fast;

  /// The tessdata_best model, when published.
  final OcrModelFile? best;

  /// The model of [quality], or null when that quality lacks it.
  OcrLanguageFile? file(OcrQuality quality) {
    final model = switch (quality) {
      OcrQuality.fast => fast,
      OcrQuality.best => best,
    };
    return model == null ? null : OcrLanguageFile._(this, quality, model);
  }

  /// Whether [query] matches either name or the code.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        native.toLowerCase().contains(q) ||
        english.toLowerCase().contains(q) ||
        code.startsWith(q);
  }

  @override
  String toString() => code;
}

/// A language's model of one quality, as the downloader sees it.
@immutable
final class OcrLanguageFile implements Downloadable {
  const new _(this.language, this.quality, this._model);

  /// The language.
  final OcrLanguage language;

  /// Its quality.
  final OcrQuality quality;

  final OcrModelFile _model;

  @override
  String get id => '${quality.name}/${language.code}';

  /// Each quality in its own folder: that folder is Tesseract's datapath.
  @override
  String get fileName => '${quality.name}/${language.code}.traineddata';

  @override
  Uri get uri => Uri.parse(
    'https://raw.githubusercontent.com/tesseract-ocr/'
    'tessdata_${quality.name}/'
    '${quality == OcrQuality.fast ? tessdataFastCommit : tessdataBestCommit}/'
    '${language.code}.traineddata',
  );

  @override
  int get bytes => _model.bytes;

  @override
  String get sha256 => _model.sha256;

  @override
  bool operator ==(Object other) => other is OcrLanguageFile && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// The language with [code], or null.
OcrLanguage? ocrLanguageByCode(String? code) {
  for (final language in ocrLanguages) {
    if (language.code == code) return language;
  }
  return null;
}
