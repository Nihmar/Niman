// Generates the test fixture corpus: markdown notes of ascending size with
// random-but-valid content (every Markdown extra the app supports).
//
// Usage (from the repo root):
//
//     dart run tool/generate_markdown_fixtures.dart
//
// Output: `test/fixtures/markdown/fixture-<size>.md` — committed; tests load
// them by path. The generator is deterministic (fixed seeds), so rerunning
// reproduces the corpus on this machine. The committed files are the source
// of truth; regenerate only to change the corpus itself.
import 'dart:io';
import 'dart:math';

/// Word bank the random text is drawn from.
const List<String> _words = <String>[
  'amber', 'anchor', 'arch', 'argue', 'arm', 'artifact', 'array', 'arrive',
  'ask', 'assembler', 'assemble', 'assume', 'attention', 'audit', 'autumn',
  'avenue', 'balance', 'barrel', 'barn', 'basin', 'batch', 'beam', 'bear',
  'border', 'borrow', 'bound', 'bowl', 'branch', 'bridge', 'bucket', 'burn',
  'burst', 'canal', 'candle', 'canvas', 'cargo', 'carve', 'cave', 'chain',
  'channel', 'charge', 'charm', 'chart', 'chase', 'cheese', 'chest', 'chess',
  'chord', 'chunk', 'circle', 'claim', 'clay', 'clean', 'cliff', 'clock',
  'close', 'cloth', 'cloud', 'coal', 'coast', 'coil', 'collect', 'color',
  'column', 'comb', 'come', 'command', 'common', 'compact', 'compare',
  'compass', 'compound', 'compute', 'concentrate', 'conduct', 'cone',
  'connect', 'console', 'constant', 'contain', 'container', 'context',
  'contrast', 'control', 'convert', 'cookie', 'copy', 'corner', 'couch',
  'cousin', 'cover', 'crack', 'craft', 'crash', 'crawl', 'crayon', 'cream',
  'creek', 'credit', 'crisp', 'crop', 'crystal', 'curve', 'cycle', 'damage',
  'dance', 'dawn', 'decay', 'deck', 'deep', 'delta', 'density', 'depth',
  'derive', 'describe', 'design', 'detail', 'detect', 'device', 'diamond',
  'diffusion', 'digest', 'digital', 'dimension', 'direct', 'disc', 'discuss',
  'distant', 'divide', 'document', 'domain', 'donkey', 'double', 'doubt',
  'down', 'draft', 'drain', 'draw', 'dream', 'dress', 'drink', 'drive',
  'drum', 'dust', 'duty', 'dynamic', 'eagle', 'early', 'earth', 'edge',
  'editor', 'effort', 'eight', 'element', 'elder', 'elect', 'elevator',
  'emerald', 'emphasis', 'empty', 'enable', 'encounter', 'end', 'engine',
  'enterprise', 'entity', 'envoy', 'equal', 'erase', 'error', 'escape',
  'essay', 'estimate', 'event', 'everybody', 'exactly', 'example', 'expect',
  'explain', 'export', 'extend', 'factory', 'fade', 'fall', 'family',
  'famous', 'fast', 'federal', 'fetch', 'field', 'fifty', 'figure',
  'filter', 'finger', 'finish', 'fire', 'first', 'fish', 'flash',
  'flavor', 'flexible', 'flip', 'floor', 'flower', 'fluid', 'flush',
  'focus', 'fog', 'follow', 'force', 'forest', 'form', 'forward',
  'foundation', 'frame', 'free', 'fresh', 'front', 'fuel', 'full',
  'function', 'funny', 'future', 'gain', 'gallery', 'gap', 'gather',
  'general', 'genre', 'gentle', 'ghost', 'giant', 'gift', 'given',
  'glance', 'glass', 'global', 'globe', 'goat', 'gold', 'golden',
  'good', 'grain', 'grant', 'grass', 'gravity', 'gray', 'green',
  'grid', 'ground', 'group', 'grow', 'guard', 'guess', 'guide',
  'hair', 'half', 'hammer', 'hand', 'handle', 'happen', 'happy',
  'harbor', 'harm', 'hat', 'header', 'height', 'help', 'hero',
  'hill', 'history', 'hold', 'hole', 'honey', 'hook', 'hope',
  'horse', 'hotel', 'hour', 'house', 'huge', 'human',
  'humor', 'hunt', 'hundred', 'hunt', 'ice', 'idea', 'ideal',
  'imagine', 'impact', 'import', 'impossible', 'improve', 'include',
  'income', 'index', 'indicate', 'industry', 'inform', 'initial',
  'insert', 'instance', 'instruction', 'instrument', 'integrate',
  'interest', 'internal', 'internet', 'interact', 'interval',
  'investigate', 'iron', 'island', 'issue', 'item',
  'jacket', 'jelly', 'jungle', 'jump', 'jury', 'justice',
  'key', 'kick', 'kid', 'kind', 'king', 'kitchen', 'knee',
  'knife', 'knowledge', 'label', 'ladder', 'lake', 'land',
  'language', 'lane', 'large', 'last', 'later', 'laugh',
  'layer', 'lead', 'learn', 'left', 'leg', 'length',
  'letter', 'level', 'life', 'light', 'like', 'limit',
  'line', 'link', 'lion', 'list', 'listen', 'little',
  'live', 'local', 'logic', 'long', 'look', 'loop',
  'lord', 'lose', 'lot', 'loud', 'love', 'lower',
  'lucky', 'lunch', 'machine', 'magic', 'mail', 'main',
  'major', 'make', 'male', 'manage', 'manager', 'manual',
  'map', 'market', 'marriage', 'master', 'match', 'material', 'matter',
  'maximum', 'maybe', 'meat', 'measure', 'medical', 'media',
  'member', 'memory', 'mention', 'menu', 'message', 'metal',
  'meter', 'middle', 'might', 'military', 'milk', 'million', 'mind',
  'minister', 'minor', 'minute', 'mirror', 'miss', 'mission',
  'mix', 'mobile', 'model', 'modular', 'module', 'moment',
  'money', 'monitor', 'month', 'moral', 'more', 'morning',
  'most', 'mother', 'motion', 'motor', 'mount', 'mountain',
  'mouse', 'mouth', 'move', 'movement', 'much', 'mud',
  'music', 'muscle', 'nail', 'name', 'narrow', 'national',
  'nature', 'near', 'nearly', 'neck', 'need', 'negative',
  'neither', 'nerve', 'network', 'never', 'news', 'newspaper',
  'next', 'nice', 'night', 'noise', 'none', 'normal',
  'north', 'nose', 'not', 'note', 'nothing', 'notice',
  'novel', 'number', 'object', 'obtain', 'occur', 'ocean',
  'offer', 'office', 'official', 'often', 'oil', 'older',
  'once', 'only', 'open', 'operate', 'operation', 'opinion',
  'option', 'orange', 'order', 'organize', 'origin', 'original',
  'other', 'output', 'outside', 'overall', 'overcome', 'page',
  'paint', 'pair', 'panel', 'paper', 'parent', 'park',
  'part', 'particular', 'pass', 'passage', 'path', 'pattern',
  'pause', 'peace', 'pen', 'percent', 'perfect', 'perform',
  'period', 'permission', 'person', 'phase', 'phone', 'physics',
  'pick', 'picture', 'piece', 'place', 'plan', 'plane',
  'plant', 'plate', 'play', 'player', 'plot', 'plug',
  'poem', 'poetry', 'point', 'polish', 'polite', 'politics',
  'pollution', 'pool', 'poor', 'popular', 'position', 'positive',
  'power', 'practical', 'present', 'press', 'pretty', 'prevent',
  'price', 'print', 'prior', 'private', 'probably', 'process',
  'produce', 'product', 'program', 'project', 'property', 'proportion',
  'protect', 'provide', 'public', 'pull', 'pure', 'purpose',
  'push', 'quality', 'query', 'question', 'quick', 'quiet',
  'race', 'radio', 'rain', 'range', 'rank', 'rapid',
  'rare', 'rate', 'reach', 'react', 'read', 'real',
  'realize', 'reason', 'receive', 'recent', 'record', 'reduce', 'reflect',
  'region', 'register', 'regulate', 'reject', 'relate', 'relationship',
  'release', 'religion', 'remain', 'remember', 'remove', 'render',
  'renew', 'repeat', 'report', 'represent', 'request', 'require',
  'reserve', 'resource', 'respond', 'response', 'respect', 'restore',
  'restrict', 'result', 'retain', 'return', 'reveal', 'reverse',
  'review', 'reward', 'rhythm', 'rice', 'rich', 'ride',
  'right', 'rise', 'risk', 'river', 'road', 'rock',
  'roll', 'roof', 'room', 'root', 'rose', 'rough',
  'round', 'route', 'row', 'royal', 'rule', 'run',
  'rural', 'sad', 'safe', 'sail', 'salt', 'sample',
  'sand', 'save', 'scale', 'scene', 'scheme', 'science',
  'score', 'sea', 'season', 'seat', 'second', 'secret',
  'section', 'secure', 'seed', 'seek', 'seem', 'select',
  'self', 'sell', 'senior', 'sense', 'sequence', 'serve',
  'service', 'session', 'settle', 'seven', 'several', 'shadow',
  'shape', 'share', 'sharp', 'shield', 'shift', 'shine',
  'ship', 'shirt', 'shop', 'short', 'shot', 'shoulder',
  'shout', 'show', 'shrink', 'sick', 'side', 'signal',
  'silent', 'silver', 'similar', 'simple', 'since', 'sing',
  'sister', 'six', 'size', 'skill', 'skin', 'sky',
  'slice', 'slide', 'slim', 'sleep', 'slope', 'slow',
  'small', 'smile', 'smoke', 'smooth', 'social', 'society',
  'soft', 'soldier', 'solid', 'solution', 'solve', 'somebody',
  'song', 'soon', 'sound', 'south', 'space', 'spare',
  'special', 'specific', 'speed', 'spell', 'spend', 'spice',
  'spine', 'spirit', 'split', 'spoil', 'sport', 'spot',
  'spread', 'spring', 'square', 'stable', 'stage', 'stand',
  'star', 'start', 'statement', 'station', 'status', 'step',
  'stick', 'stock', 'stone', 'stop', 'store', 'storm',
  'story', 'strange', 'strategy', 'stream', 'street', 'strength',
  'strike', 'strong', 'structure', 'student', 'study', 'style',
  'subject', 'submit', 'subtle', 'sugar', 'suggest', 'suit',
  'summer', 'supply', 'support', 'suppose', 'surface', 'surprise',
  'survey', 'switch', 'symbol', 'system', 'table', 'tail',
  'take', 'talk', 'tall', 'target', 'task', 'taste',
  'teach', 'team', 'tear', 'technique', 'technology', 'teeth',
  'temperature', 'temporary', 'tend', 'term', 'text', 'thank',
  'theater', 'theory', 'thin', 'thing', 'think', 'third',
  'this', 'thorn', 'thousand', 'thread', 'threat', 'threshold',
  'throughout', 'throw', 'thus', 'ticket', 'tie', 'tissue',
  'title', 'toe', 'together', 'tonight', 'tool', 'top',
  'tough', 'tower', 'town', 'trace', 'track', 'trade',
  'tradition', 'traffic', 'train', 'transfer', 'translate', 'travel',
  'treat', 'tree', 'trend', 'trial', 'tribe', 'trick',
  'trigger', 'trip', 'trouble', 'truck', 'trust', 'try',
  'tunnel', 'turn', 'twice', 'type', 'uncle', 'understand',
  'unit', 'unite', 'universe', 'universal', 'update', 'urban',
  'use', 'usual', 'useful', 'value', 'van', 'variable',
  'variation', 'vary', 'vast', 'vector', 'version', 'vertical',
  'victim', 'view', 'village', 'vital', 'voice', 'volume',
  'vote', 'wage', 'wait', 'wake', 'walk', 'wall',
  'ward', 'warm', 'warn', 'wash', 'waste', 'watch',
  'water', 'wave', 'way', 'weather', 'web', 'week',
  'weight', 'welcome', 'west', 'western', 'wheel', 'where',
  'whole', 'wide', 'wife', 'wild', 'will', 'window',
  'wine', 'wing', 'winter', 'wire', 'wisdom', 'wise',
  'wish', 'wood', 'word', 'work', 'worker', 'world',
  'wound', 'write', 'writer', 'yard', 'year', 'yellow',
  'young', 'youth',
];

/// Math templates; the set covers the spec's KaTeX cases (matrix,
/// aligned/cases, `\text`, `\newcommand`) so fixtures exercise them.
const List<String> _displayMath = <String>[
  r'f(x) = \sum_{i=1}^{n} i \cdot x^{i}',
  r'\int_0^1 x^2\,dx = \frac{1}{3}',
  r'\begin{pmatrix} a_{11} & a_{12} \\ a_{21} & a_{22} \end{pmatrix}',
  r'g(t) = \begin{cases} t & \text{if } t \ge 0 \\ -t & \text{otherwise} \end{cases}',
  r'\begin{aligned} a &= b + c \\ d &= e - f \end{aligned}',
  r'\text{E}[X] = \mu \quad \text{where } \mu \in \mathbb{R}',
  r'\sqrt[n]{a} + \lim_{m \to \infty} \frac{m}{m+1}',
  r'\newcommand{\R}{\mathbb{R}}\quad x \in \R,\quad \|x\| = \sqrt{x_1^2 + x_2^2}',
];

const List<String> _inlineMath = <String>[
  r'$x^2$',
  r'$\frac{a}{b}$',
  r'$\sqrt{n}$',
  r'$\alpha + \beta$',
  r'$\lim_{n \to \infty} (1 + \frac{1}{n})^n = e$',
  r'$\nabla \cdot \vec{F} = 0$',
];

const List<String> _codeLangs = <String>[
  'dart',
  'python',
  'javascript',
  'sql',
  '',
];

const List<String> _tags = <String>[
  'project', 'draft', 'idea', 'reference', 'work', 'home', 'notes', 'math',
];

/// One fixture: target size in bytes and the seed that generates it.
final class FixtureSpec {
  const FixtureSpec(this.fileName, this.targetBytes, this.seed);

  final String fileName;
  final int targetBytes;
  final int seed;
}

/// The corpus, in ascending size order.
const List<FixtureSpec> fixtures = <FixtureSpec>[
  FixtureSpec('fixture-1kb.md', 1 << 10, 1001),
  FixtureSpec('fixture-10kb.md', 10 * 1024, 1002),
  FixtureSpec('fixture-50kb.md', 50 * 1024, 1003),
  FixtureSpec('fixture-200kb.md', 200 * 1024, 1004),
  FixtureSpec('fixture-500kb.md', 500 * 1024, 1005),
  FixtureSpec('fixture-1mb.md', 1024 * 1024, 1006),
];

final class _Gen {
  _Gen(this.rand, this.out) {
    _headingCounter = _randInt(0, 40);
  }

  final Random rand;
  final StringBuffer out;
  late int _headingCounter;
  var _footnoteCount = 0;
  final List<String> _footnoteDefs = <String>[];

  int get size => out.length;

  String get text => out.toString();

  int _randInt(int min, int maxExclusive) =>
      rand.nextInt(maxExclusive - min) + min;

  String _word() => _words[rand.nextInt(_words.length)];

  String _sentence() {
    final len = _randInt(5, 13);
    final buf = StringBuffer(_word().capitalizeFirst);
    if (rand.nextInt(100) < 40) {
      buf.write(' ${_inlineSpan()}');
    }
    for (var i = 1; i < len; i++) {
      buf.write(' ${_word()}');
    }
    return '$buf.';
  }

  /// One inline span inserted into paragraph text.
  String _inlineSpan() {
    final span = _randInt(0, 100);
    if (span < 22) return '**${_word()} ${_word()}**';
    if (span < 42) return '*${_word()}*';
    if (span < 58) return '`_${_word()}${_randInt(2, 99)}_`';
    if (span < 70) return '[${_word()} link](https://example.com/${_randInt(1, 999)})';
    if (span < 78) return '~~${_word()}~~';
    if (span < 88) return _inlineMath[_randInt(0, _inlineMath.length)];
    if (span < 96) return '#${_tags[_randInt(0, _tags.length)]}';
    return '[[${_word().capitalizeFirst} ${_word().capitalizeFirst}]]';
  }

  void _paragraph({bool withFootnote = false}) {
    final sentences = _randInt(2, 6);
    final buf = StringBuffer();
    for (var i = 0; i < sentences; i++) {
      if (i > 0) buf.write(' ');
      buf.write(_sentence());
    }
    if (withFootnote && _footnoteDefs.length < 40) {
      _footnoteCount++;
      final def = '${_word()} ${_word()} ${_word()} ${_word()}.';
      _footnoteDefs.add(def);
      buf.write(' [^$_footnoteCount]');
    }
    _emitLine(buf.toString());
  }

  void _heading() {
    _headingCounter++;
    final level = _randInt(0, 100) < 25 ? 2 : (_randInt(0, 100) < 70 ? 3 : 4);
    final hashes = '#' * level;
    _emitLine('$hashes Section $_headingCounter ${_word().capitalizeFirst} '
        '${_word().capitalizeFirst}');
  }

  void _bulletList() {
    final n = _randInt(2, 6);
    final task = rand.nextInt(100) < 40;
    for (var i = 0; i < n; i++) {
      final check = task
          ? (rand.nextBool() ? '[x] ' : '[ ] ')
          : '';
      _emitLine('- $check${_word()} ${_word()} ${_word()}');
      if (rand.nextBool() && !task) {
        _emitLine('  - nested ${_word()} ${_word()}');
      }
    }
  }

  void _orderedList() {
    final n = _randInt(2, 5);
    for (var i = 1; i <= n; i++) {
      _emitLine('$i. ${_word()} ${_word()} ${_word()}');
    }
  }

  void _table() {
    final cols = _randInt(2, 5);
    final headers = List<String>.generate(cols, (_) => _word().capitalizeFirst);
    _emitLine('| ${headers.join(' | ')} |');
    final aligns = List<String>.generate(
      cols,
      (_) {
        final a = _randInt(0, 3);
        return a == 0 ? '---' : a == 1 ? ':---' : '---:';
      },
    );
    _emitLine('| ${aligns.join(' | ')} |');
    for (var r = 0; r < _randInt(2, 6); r++) {
      final cells = List<String>.generate(cols, (_) => _word());
      _emitLine('| ${cells.join(' | ')} |');
    }
  }

  void _codeBlock() {
    final lang = _codeLangs[_randInt(0, _codeLangs.length)];
    _emitLine('```$lang');
    final n = _randInt(3, 8);
    for (var i = 0; i < n; i++) {
      final kind = _randInt(0, 4);
      if (kind == 0) {
        _emitLine('const v_${_randInt(0, 999)} = ${_randInt(0, 999)};');
      } else if (kind == 1) {
        _emitLine('fn_${_word()}(${_word()}, ${_word()});');
      } else if (kind == 2) {
        _emitLine('// ${_word()} ${_word()}');
      } else {
        _emitLine('  let ${_word()} = [${_randInt(0, 9)}, ${_randInt(0, 9)}];');
      }
    }
    _emitLine('```');
  }

  void _displayMathBlock() {
    final expr = _displayMath[_randInt(0, _displayMath.length)];
    if (rand.nextBool()) {
      _emitLine(r'$$ ' '$expr ' r'$$');
    } else {
      _emitLine(r'$$');
      _emitLine(expr);
      _emitLine(r'$$');
    }
  }

  void _blockquote() {
    final n = _randInt(1, 3);
    for (var i = 0; i < n; i++) {
      _emitLine('> ${_word().capitalizeFirst} ${_word()} ${_word()}');
    }
  }

  void _imageParagraph() {
    _emitLine('![Figure ${_randInt(0, 999)}](assets/img-${_randInt(0, 999)}.png)');
  }

  void _horizontalRule() {
    _emitLine('---');
  }

  /// Emits a full block followed by a blank line.
  void block() {
    final pick = _randInt(0, 100);
    switch (pick) {
      case < 30:
        _paragraph(withFootnote: rand.nextInt(100) < 15);
      case < 42:
        _heading();
      case < 54:
        _bulletList();
      case < 62:
        _orderedList();
      case < 72:
        _table();
      case < 82:
        _codeBlock();
      case < 90:
        _displayMathBlock();
      case < 95:
        _blockquote();
      case < 98:
        _imageParagraph();
      default:
        _horizontalRule();
    }
    _emitLine('');
  }

  void _emitLine(String line) {
    out.writeln(line);
  }

  void finish() {
    for (var i = 0; i < _footnoteDefs.length; i++) {
      _emitLine('');
      _emitLine('[^${i + 1}]: ${_footnoteDefs[i]}');
    }
  }

  void frontMatter() {
    final w1 = _word().capitalizeFirst;
    final w2 = _word().capitalizeFirst;
    final title = '$w1 $w2 ${_randInt(1, 999)}';
    final tagCount = _randInt(1, 4);
    final used = <String>{};
    final tagLines = <String>[];
    while (tagLines.length < tagCount) {
      final t = _tags[_randInt(0, _tags.length)];
      if (used.add(t)) {
        tagLines.add('  - $t');
      }
    }
    out.writeAll(
      <String>[
        '---',
        'title: "$title"',
        'tags:',
        ...tagLines,
        'date: ${_date()}',
        'pinned: ${rand.nextBool()}',
        'aliases:',
        '  - "${_word().capitalizeFirst} ${_word().capitalizeFirst}"',
        '---',
        '',
        '',
      ],
      '\n',
    );
  }

  String _date() {
    final y = _randInt(2019, 2026);
    final m = _randInt(1, 13).toString().padLeft(2, '0');
    final d = _randInt(1, 29).toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

extension on String {
  String get capitalizeFirst =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}

void main() {
  const dirPath = 'test/fixtures/markdown';
  final old = Directory(dirPath);
  if (old.existsSync()) {
    old.deleteSync(recursive: true);
  }
  Directory(dirPath).createSync(recursive: true);
  for (final spec in fixtures) {
    final gen = _Gen(Random(spec.seed), StringBuffer())..frontMatter();
    while (gen.size < spec.targetBytes) {
      gen.block();
    }
    gen.finish();
    final text = gen.text;
    File('$dirPath/${spec.fileName}').writeAsStringSync(text);
    stderr.writeln(
      '${spec.fileName}: ${text.length} bytes (${text.length / 1024} KiB)',
    );
  }
}
