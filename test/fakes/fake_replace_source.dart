import 'package:copist/src/search/replace.dart';

/// In-memory [ReplaceSource] for widget tests: records every request and
/// returns [report] (configurable per test).
final class FakeReplaceSource implements ReplaceSource {
  /// The notes count [countNotes] reports.
  int noteCount = 0;

  /// The report every [replaceAll] returns.
  ReplaceReport report = const ReplaceReport(
    notesScanned: 2,
    notesChanged: 2,
    occurrences: 5,
    skipped: [],
  );

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
  requests = [];

  @override
  Future<int> countNotes(String term) async => noteCount;

  @override
  Future<ReplaceReport> replaceAll({
    required String term,
    required String replacement,
    required bool caseSensitive,
    Set<String>? only,
    Set<String> skip = const {},
  }) async {
    requests.add((
      term: term,
      replacement: replacement,
      caseSensitive: caseSensitive,
      only: only,
      skip: skip,
    ));
    return report;
  }
}
