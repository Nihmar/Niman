/// One file the app downloads on demand: a transcription model, the OCR
/// engine, an OCR language.
abstract interface class Downloadable {
  /// The stable id the downloader keys its state by.
  String get id;

  /// Where the file is published.
  Uri get uri;

  /// The published size, shown before a download reports its own.
  int get bytes;

  /// The file's path under the download directory; may hold a folder
  /// (`fast/ita.traineddata`).
  String get fileName;

  /// The lowercase hex SHA-256 the finished file must have; null when
  /// the catalog pins none.
  String? get sha256;
}
