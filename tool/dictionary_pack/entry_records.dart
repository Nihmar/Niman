// The records the pipeline sorts. Both kinds are keyed by a headword, so the
// merge that writes the pack meets each entry with everything known about it.
import 'dart:convert';
import 'dart:typed_data';

/// A source entry of a headword, rendered, as it travels through the sort:
/// the part of the pack's entry that one wiktextract entry contributes.
final class EntryPart {
  /// A part: [seq] is its place in the input, [senses] how many senses its
  /// [section] holds, and [forms] its forms as `tags<TAB>form` lines.
  const new(this.seq, this.senses, this.section, this.forms);

  /// What the sort keeps equal headwords in the input's order by.
  final int seq;

  /// The senses in [section].
  final int senses;

  /// The rendered `<section>`.
  final String section;

  /// The forms, each as `tags<TAB>form`.
  final List<String> forms;

  /// The value of a sort record.
  Uint8List encode() {
    final section = utf8.encode(this.section);
    final forms = utf8.encode(this.forms.join('\n'));
    final bytes = Uint8List(16 + section.length + forms.length);
    ByteData.sublistView(bytes)
      ..setUint64(0, seq)
      ..setUint32(8, senses)
      ..setUint32(12, section.length);
    bytes
      ..setRange(16, 16 + section.length, section)
      ..setRange(16 + section.length, bytes.length, forms);
    return bytes;
  }
}

/// The part [EntryPart.encode] wrote.
EntryPart decodeEntryPart(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final sectionLength = data.getUint32(12);
  final forms = utf8.decode(Uint8List.sublistView(bytes, 16 + sectionLength));
  return EntryPart(
    data.getUint64(0),
    data.getUint32(8),
    utf8.decode(Uint8List.sublistView(bytes, 16, 16 + sectionLength)),
    forms.isEmpty ? const [] : forms.split('\n'),
  );
}

/// What the English edition knows about a language that has an edition of
/// its own, kept by lemma: that the lemma exists there, and the forms it
/// lists for it. The own edition's pack borrows the forms and is measured
/// against the headwords.
sealed class EnglishFact {
  const new();

  /// The fact in [value], a sort record's value.
  static EnglishFact decode(Uint8List value) {
    if (value[0] == 0) {
      return EnglishHeadword(ByteData.sublistView(value).getUint32(1));
    }
    final text = utf8.decode(Uint8List.sublistView(value, 1));
    final tab = text.indexOf('\t');
    return EnglishForm(text.substring(tab + 1), text.substring(0, tab));
  }
}

/// The English edition has an entry for the lemma, with [senses] senses.
final class EnglishHeadword extends EnglishFact {
  /// A headword of [senses] senses.
  const new(this.senses);

  /// How many.
  final int senses;

  /// The value of a sort record.
  Uint8List encode() {
    final bytes = Uint8List(5);
    ByteData.sublistView(bytes).setUint32(1, senses);
    return bytes;
  }
}

/// The English edition lists [form] for the lemma, with [tags].
final class EnglishForm extends EnglishFact {
  /// A form.
  const new(this.form, this.tags);

  /// The form.
  final String form;

  /// Its tags, space-separated.
  final String tags;

  /// The value of a sort record.
  Uint8List encode() => Uint8List.fromList([1, ...utf8.encode('$tags\t$form')]);
}
