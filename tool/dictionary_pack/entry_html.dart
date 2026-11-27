// The HTML a pack's entries are written in: the closed grammar of
// docs/records/dictionary.md ("An entry"). Every text is escaped, and nothing
// outside the grammar is ever written, since the app's parser reads anything
// else as text.
import 'source_entry.dart';

/// [text] with the four characters the grammar escapes.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// A tag list as the attribute value `data-tags` holds: space-separated.
String _tags(List<String> tags) => escapeHtml(tags.join(' '));

/// The `<section>` of [entry]: its numbered senses, then the lemma it is a
/// form of, when it is.
String renderSection(SourceEntry entry) {
  final out = StringBuffer()
    ..write('<section data-pos="${escapeHtml(entry.pos)}" ')
    ..write('data-tags="${_tags(entry.tags)}"><ol>');
  final formOf = <String, List<String>>{};
  for (final sense in entry.senses) {
    out.write('<li>');
    if (sense.qualifier.isNotEmpty) {
      out.write('<span class="q">${escapeHtml(sense.qualifier)}</span> ');
    }
    out.write(escapeHtml(sense.gloss));
    if (sense.examples.isNotEmpty) {
      out.write('<ul class="ex">');
      for (final example in sense.examples) {
        out.write('<li>${escapeHtml(example)}</li>');
      }
      out.write('</ul>');
    }
    out.write('</li>');
    for (final lemma in sense.formOf) {
      formOf.putIfAbsent(lemma, () => sense.tags);
    }
  }
  out.write('</ol>');
  formOf.forEach((lemma, tags) {
    out.write(
      '<p class="form-of" data-tags="${_tags(tags)}">'
      '${escapeHtml(lemma)}</p>',
    );
  });
  out.write('</section>');
  return out.toString();
}

/// One of the headword's forms, as the `forms` division lists it.
String renderForm(String form, List<String> tags) =>
    '<span data-tags="${_tags(tags)}">${escapeHtml(form)}</span>';

/// The whole entry of [headword]: its [sections], then its [forms] (each
/// already rendered by [renderForm]).
String renderEntry(
  String headword,
  Iterable<String> sections,
  Iterable<String> forms,
) {
  final out = StringBuffer('<div class="entry"><h1>')
    ..write(escapeHtml(headword))
    ..write('</h1>');
  sections.forEach(out.write);
  if (forms.isNotEmpty) {
    out.write('<div class="forms">');
    forms.forEach(out.write);
    out.write('</div>');
  }
  out.write('</div>');
  return out.toString();
}
