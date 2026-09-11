import 'package:niman/src/search/replace.dart';

/// In-memory [ReplaceSource] for widget tests: records every request and
/// returns the configured preview/report.
final class FakeReplaceSource implements ReplaceSource {
  /// The match notes [previewMatches] returns.
  List<ReplaceMatchNote> preview = [];

  /// The report every [replaceAll] returns.
  ReplaceReport report = const ReplaceReport(
    notesScanned: 2,
    notesChanged: 2,
    occurrences: 5,
    skipped: [],
  );

  /// Every preview request, in order.
  final List<({String term, bool caseSensitive, String? onlyPath})> previews =
      [];

  /// Every replace request, in order.
  final List<
    ({
      String term,
      String replacement,
      bool caseSensitive,
      Set<String>? only,
      Set<String> skip,
    })
  >
  replaceRequests = [];

  @override
  Future<List<ReplaceMatchNote>> previewMatches(
    String term, {
    required bool caseSensitive,
    String? onlyPath,
  }) async {
    previews.add((
      term: term,
      caseSensitive: caseSensitive,
      onlyPath: onlyPath,
    ));
    return preview;
  }

  @override
  Future<ReplaceReport> replaceAll({
    required String term,
    required String replacement,
    required bool caseSensitive,
    Set<String>? only,
    Set<String> skip = const {},
  }) async {
    replaceRequests.add((
      term: term,
      replacement: replacement,
      caseSensitive: caseSensitive,
      only: only,
      skip: skip,
    ));
    return report;
  }
}
