// The small hand-made packs the engine's tests (and the pipeline's) read: a
// few Italian and English entries in the HTML grammar of the pack format.
//
// `test/fixtures/dictionary/niman-it/` and `niman-en/` are these, written by
// `writeFixturePacks` and committed byte for byte, so a test of another
// module can read them without this helper; `fixture_packs_test.dart` fails
// when the two drift apart.
import 'package:path/path.dart' as p;

import 'pack_writer.dart';

String _sense(
  String gloss, {
  String? qualifier,
  List<String> examples = const [],
}) {
  final q = qualifier == null ? '' : '<span class="q">$qualifier</span> ';
  final ex = examples.isEmpty
      ? ''
      : '\n        <ul class="ex">${[for (final e in examples) '<li>$e</li>'].join()}</ul>';
  return '      <li>$q$gloss$ex</li>';
}

String _section(
  String pos,
  String tags,
  List<String> senses, {
  String? lemma,
  String lemmaTags = '',
}) {
  final formOf = lemma == null
      ? ''
      : '\n    <p class="form-of" data-tags="$lemmaTags">$lemma</p>';
  return '  <section data-pos="$pos" data-tags="$tags">\n'
      '    <ol>\n${senses.join('\n')}\n    </ol>$formOf\n'
      '  </section>';
}

PackEntry _entry(
  String headword,
  List<String> sections, {
  List<(String, String)> forms = const [],
}) {
  final spans = [
    for (final (form, tags) in forms) '<span data-tags="$tags">$form</span>',
  ];
  final list = forms.isEmpty
      ? ''
      : '\n  <div class="forms">${spans.join(', ')}</div>';
  return (
    headword: headword,
    html:
        '<div class="entry">\n  <h1>$headword</h1>\n'
        '${sections.join('\n')}$list\n</div>',
  );
}

/// The Italian entries.
final List<PackEntry> itEntries = [
  _entry('a priori', [
    _section('adv', '', [_sense('Based on reasoning, not on experience.')]),
  ]),
  _entry('acqua', [
    _section('noun', 'feminine', [
      _sense(
        'Colourless liquid that falls as rain.',
        examples: ["bere un bicchiere d'acqua"],
      ),
    ]),
  ]),
  _entry('amare', [
    _section('verb', 'transitive', [_sense('To love.')]),
  ]),
  _entry(
    'amo',
    [
      _section('noun', 'masculine', [_sense('A fishing hook.')]),
    ],
    forms: [('ami', 'plural')],
  ),
  _entry('ancora', [
    _section('noun', 'feminine', [_sense('Anchor of a ship.')]),
    _section('adv', '', [_sense('Still, yet.'), _sense('Again.')]),
  ]),
  _entry(
    'andare',
    [
      _section('verb', 'intransitive', [
        _sense('To go.', examples: ['andare a casa']),
      ]),
    ],
    forms: [('andasse', 'subjunctive imperfect third-person singular')],
  ),
  _entry('camini', [
    _section(
      'noun',
      'masculine plural',
      [_sense('plural of camino')],
      lemma: 'camino',
      lemmaTags: 'plural',
    ),
  ]),
  _entry('camino', [
    _section('noun', 'masculine', [
      _sense('Chimney.'),
      _sense('Fireplace.', examples: ['accendere il camino']),
    ]),
  ]),
  _entry(
    'caminetto',
    [
      _section('noun', 'masculine', [
        _sense('A small fireplace.', examples: ['accendere il caminetto']),
        _sense('A <i>decorative</i> hearth.', qualifier: 'familiar'),
      ]),
    ],
    forms: [('caminetti', 'plural')],
  ),
  _entry('cammino', [
    _section('noun', 'masculine', [_sense('Walk, journey on foot.')]),
  ]),
  _entry('città', [
    _section('noun', 'feminine', [_sense('City.')]),
  ]),
];

/// The Italian forms: key to the headwords it leads to.
const Map<String, List<String>> itForms = {
  'ami': ['amare', 'amo'],
  'andasse': ['andare'],
  'caminetti': ['caminetto'],
};

/// The English entries.
final List<PackEntry> enEntries = [
  _entry('Polish', [
    _section('adj', '', [_sense('Of Poland, its people or language.')]),
    _section('noun', '', [_sense('The language of Poland.')]),
  ]),
  _entry(
    'polish',
    [
      _section('verb', '', [_sense('To make shiny by rubbing.')]),
      _section('noun', '', [_sense('A substance used for polishing.')]),
    ],
    forms: [
      ('polishes', 'third-person singular present'),
      ('polished', 'past'),
    ],
  ),
  _entry('ice', [
    _section('noun', '', [_sense('Frozen water.')]),
  ]),
  _entry('ice cream', [
    _section('noun', '', [_sense('A frozen dessert.')]),
  ]),
  _entry(
    'run',
    [
      _section('verb', '', [_sense('To move quickly on foot.')]),
    ],
    forms: [('ran', 'past'), ('running', 'participle present')],
  ),
  _entry('cat', [
    _section('noun', '', [_sense('A small domesticated feline.')]),
  ]),
];

/// The English forms.
const Map<String, List<String>> enForms = {
  'polished': ['polish'],
  'polishes': ['polish'],
  'ran': ['run'],
  'running': ['run'],
};

/// Writes `niman-it` and `niman-en` into [root] and returns the two
/// directories.
Future<List<String>> writeFixturePacks(String root) async => [
  await writePack(
    root,
    code: 'it',
    entries: itEntries,
    forms: itForms,
    definitions: 'it',
    source: 'it.wiktionary',
  ),
  await writePack(
    root,
    code: 'en',
    entries: enEntries,
    forms: enForms,
    definitions: 'en',
    source: 'en.wiktionary',
  ),
];

/// Where the committed copies are.
final String fixturePacksDirectory = p.join('test', 'fixtures', 'dictionary');
