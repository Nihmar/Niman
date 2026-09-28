// A [WikilinkSuggester] a widget test drives by hand (#475): the rows the
// panel lists, in the order the library would rank them, and the headings a
// named note answers with.
import 'package:niman/src/links/suggester.dart';

/// A canned [WikilinkSuggester] for the panel's widget tests.
final class FakeWikilinkSuggester implements WikilinkSuggester {
  /// Creates a suggester over canned rows.
  new({
    List<NoteSuggestion>? notes,
    Map<String, List<HeadingSuggestion>>? headings,
    this.places = const <BookSuggestion>[],
  }) : _notes = notes ?? const <NoteSuggestion>[],
       _headings = headings ?? const <String, List<HeadingSuggestion>>{};

  final List<NoteSuggestion> _notes;
  final Map<String, List<HeadingSuggestion>> _headings;

  /// The book forms a `#` on a PDF/EPUB answers with.
  final List<BookSuggestion> places;

  /// Every note query the panel asked for, in order.
  final List<String> noteQueries = <String>[];

  /// Every heading target the panel asked for, in order.
  final List<String> headingTargets = <String>[];

  @override
  Future<List<NoteSuggestion>> notes(String query) async {
    noteQueries.add(query);
    // A word the fake does not know matches nothing, so a test can ask for
    // the empty state without an empty library.
    if (query.isNotEmpty && query.toLowerCase().contains('zzz')) {
      return const <NoteSuggestion>[];
    }
    if (query.isEmpty) return _notes;
    final q = query.toLowerCase();
    final prefix = <NoteSuggestion>[];
    final within = <NoteSuggestion>[];
    for (final note in _notes) {
      if (note.name.toLowerCase().startsWith(q)) {
        prefix.add(note);
      } else if (note.name.toLowerCase().contains(q) ||
          (note.alias?.toLowerCase().startsWith(q) ?? false)) {
        within.add(note);
      }
    }
    return <NoteSuggestion>[...prefix, ...within];
  }

  @override
  Future<List<HeadingSuggestion>> headings(String target) async {
    headingTargets.add(target);
    return _headings[target] ?? const <HeadingSuggestion>[];
  }

  @override
  Future<List<BookSuggestion>> bookPlaces(String target) async => places;
}
