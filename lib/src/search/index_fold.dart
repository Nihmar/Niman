/// Text folded the way the word indexes fold it: the `unicode61` tokenizer
/// with `remove_diacritics 2`, which both `notes_fts` and `note_anchors_fts`
/// are built with. A word typed in a search and a word read back from a row
/// compare equal here exactly when the index says they match: `resume`
/// finds "Résumé", `ð` stays `ð` because SQLite keeps it.
///
/// The fold is SQLite's, not Unicode's: a combining accent is dropped, a
/// letter with accents becomes the plain letter SQLite's table names, and
/// every other character is lowercased one for one. The table below holds
/// only where that differs from Dart's own lowercasing, and
/// `test/unit/index_fold_test.dart` holds it to the tokenizer, character by
/// character, over the first two Unicode planes.
library;

/// [text] folded as the word index folds it: lowercase, combining accents
/// dropped, accented letters to their plain letter.
String foldForIndex(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (_isDroppedMark(rune)) continue;
    out.writeCharCode(_fold(rune));
  }
  return out.toString();
}

int _fold(int rune) {
  if (rune < 0x80) return rune >= 0x41 && rune <= 0x5A ? rune + 0x20 : rune;
  if (rune > 0xFFFF) {
    // Past the plane SQLite folds only Deseret's capitals.
    return rune >= 0x10400 && rune < 0x10428 ? rune + 40 : rune;
  }
  return _table[rune] ?? String.fromCharCode(rune).toLowerCase().codeUnitAt(0);
}

/// The combining accents the tokenizer drops from a word.
bool _isDroppedMark(int unit) =>
    unit >= 0x300 && unit <= 0x331 && _droppedMarks.contains(unit);

const Set<int> _droppedMarks = {
  0x300, 0x301, 0x302, 0x303, 0x304, 0x306, 0x307, 0x308, 0x309, 0x30A, //
  0x30B, 0x30C, 0x30F, 0x311, 0x31B, 0x323, 0x324, 0x325, 0x326, 0x327, //
  0x328, 0x32D, 0x32E, 0x330, 0x331,
};

/// Each character whose fold is not its Dart lowercase, by its fold.
const Map<String, String> _byFold = {
  'a': 'ÀÁÂÃÄÅàáâãäåĀāĂăĄąǍǎǞǟǺǻȀȁȂȃȦȧḀḁẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặÅ',
  'b': 'ḂḃḄḅḆḇ',
  'c': 'ÇçĆćĈĉĊċČčḈḉ',
  'd': 'ĎďḊḋḌḍḎḏḐḑḒḓ',
  'e': 'ÈÉÊËèéêëĒēĔĕĖėĘęĚěȄȅȆȇȨȩḔḕḖḗḘḙḚḛḜḝẸẹẺẻẼẽẾếỀềỂểỄễỆệ',
  'f': 'Ḟḟ',
  'g': 'ĜĝĞğĠġĢģǦǧǴǵḠḡ',
  'h': 'ĤĥȞȟḢḣḤḥḦḧḨḩḪḫẖ',
  'i': 'ÌÍÎÏìíîïĨĩĪīĬĭĮįǏǐȈȉȊȋḬḭḮḯỈỉỊị',
  'j': 'Ĵĵǰ',
  'k': 'ĶķǨǩḰḱḲḳḴḵ',
  'l': 'ĹĺĻļĽľḶḷḸḹḺḻḼḽ',
  'm': 'ḾḿṀṁṂṃ',
  'n': 'ÑñŃńŅņŇňǸǹṄṅṆṇṈṉṊṋ',
  'o': 'ÒÓÔÕÖòóôõöŌōŎŏŐőƠơǑǒǪǫǬǭȌȍȎȏȪȫȬȭȮȯȰȱṌṍṎṏṐṑṒṓỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợ',
  'p': 'ṔṕṖṗ',
  'r': 'ŔŕŖŗŘřȐȑȒȓṘṙṚṛṜṝṞṟ',
  's': 'ŚśŜŝŞşŠšſȘșṠṡṢṣṤṥṦṧṨṩẛ',
  't': 'ŢţŤťȚțṪṫṬṭṮṯṰṱẗ',
  'u': 'ÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųƯưǓǔǕǖǗǘǙǚǛǜȔȕȖȗṲṳṴṵṶṷṸṹṺṻỤụỦủỨứỪừỬửỮữỰự',
  'v': 'ṼṽṾṿ',
  'w': 'ŴŵẀẁẂẃẄẅẆẇẈẉẘ',
  'x': 'ẊẋẌẍ',
  'y': 'ÝýÿŶŷŸȲȳẎẏẙỲỳỴỵỶỷỸỹ',
  'z': 'ŹźŻżŽžẐẑẒẓẔẕ',
  'ȿ': 'Ȿ',
  'ɀ': 'Ɀ',
  'ɒ': 'Ɒ',
  'ɥ': 'Ɥ',
  'ɦ': 'Ɦ',
  'β': 'ϐ',
  'ε': 'ϵ',
  'θ': 'ϑ',
  'ι': 'ι',
  'κ': 'ϰ',
  'μ': 'µ',
  'π': 'ϖ',
  'ρ': 'ϱ',
  'σ': 'ς',
  'φ': 'ϕ',
  'ԥ': 'Ԥ',
  'ԧ': 'Ԧ',
  'ⳬ': 'Ⳬ',
  'ⳮ': 'Ⳮ',
  'ⳳ': 'Ⳳ',
  'ⴧ': 'Ⴧ',
  'ⴭ': 'Ⴭ',
  'ꙡ': 'Ꙡ',
  'ꞑ': 'Ꞑ',
  'ꞓ': 'Ꞓ',
  'ꞡ': 'Ꞡ',
  'ꞣ': 'Ꞣ',
  'ꞥ': 'Ꞥ',
  'ꞧ': 'Ꞧ',
  'ꞩ': 'Ꞩ',
};

final Map<int, int> _table = {
  for (final MapEntry(key: fold, value: letters) in _byFold.entries)
    for (final unit in letters.codeUnits) unit: fold.codeUnitAt(0),
};
