// The book-place hints the suggester offers (#475): `page=` for a PDF and
// `chapter=` for an EPUB carry a dimmed note beside them, and that note is a
// label, so it follows the language the app speaks.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/suggester.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  late IndexDatabase db;
  late IndexWikilinkSuggester suggester;

  setUp(() {
    db = IndexDatabase(NativeDatabase.memory());
    suggester = IndexWikilinkSuggester(db, readHeadings: (_) async => null);
  });
  tearDown(() => db.close());

  test('the PDF and EPUB hints are the app language', () async {
    AppLanguages.choice = AppLanguage.english;
    final pdf = await suggester.bookPlaces('Dune.pdf');
    expect(pdf.single.form, 'page=');
    expect(pdf.single.hint, 'type a number');
    final epub = await suggester.bookPlaces('Dune.epub');
    expect(epub.single.form, 'chapter=');
    expect(epub.single.hint, 'name a file in the book');

    AppLanguages.choice = AppLanguage.italian;
    expect(
      (await suggester.bookPlaces('Dune.pdf')).single.hint,
      'digita un numero',
    );
    expect(
      (await suggester.bookPlaces('Dune.epub')).single.hint,
      'indica un file del libro',
    );
  });
}
