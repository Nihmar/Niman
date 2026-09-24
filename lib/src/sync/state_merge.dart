/// Merges for the library state files (`libraryStateFiles`): two JSON
/// objects, where a line merge could break the syntax and a whole-file
/// "newest wins" drops whatever the older side changed, and the personal
/// dictionary, a set of words.
///
/// Pure: the engine reads both sides and the base, and writes the result.
library;

import 'dart:convert';

/// `.niman/settings.json` merged key by key over [base], the content both
/// sides last agreed on (null when there is none).
///
/// A key only one side changed (added, edited or removed) takes that
/// side; a key both changed differently takes the side whose file is
/// newer ([localNewer]). Without a base nothing says which side changed
/// a key, so a key one side has and the other lacks is kept, and a key
/// both have with different values takes the newer side.
///
/// Returns the merged file text (two-space indent, final newline, local
/// key order first), or null when a side does not parse as a JSON object
/// — then only the whole file can be chosen.
String? mergeSettingsJson({
  required String? base,
  required String local,
  required String remote,
  required bool localNewer,
}) {
  final l = _object(local);
  final r = _object(remote);
  if (l == null || r == null) return null;
  final b = base == null ? null : _object(base);
  final merged = <String, Object?>{};
  for (final key in {...l.keys, ...r.keys}) {
    final pick = _pick(
      key,
      local: l,
      remote: r,
      base: b,
      localNewer: localNewer,
    );
    if (pick.present) merged[key] = pick.value;
  }
  return _encode(merged);
}

/// `.niman/counters.json` merged: every counter is the highest either
/// side reached, so a number a template already handed out on one device
/// is never handed out again on the other.
///
/// Counters only grow, so no base is needed. Returns null when a side
/// does not parse as a JSON object.
String? mergeCountersJson({required String local, required String remote}) {
  final l = _object(local);
  final r = _object(remote);
  if (l == null || r == null) return null;
  final merged = <String, Object?>{};
  for (final key in {...l.keys, ...r.keys}) {
    final a = l[key];
    final b = r[key];
    merged[key] = switch ((a, b)) {
      (final int x, final int y) => x > y ? x : y,
      (final int x, _) => x,
      (_, final int y) => y,
      _ => a ?? b,
    };
  }
  return _encode(merged);
}

/// `.niman/dictionary.txt` merged word by word over [base], the list both
/// sides last agreed on (null when there is none): a word either side
/// added is in, a word either side removed is out. Without a base it is
/// the union.
///
/// Words compare case-insensitively, as the spell check reads them; the
/// form kept is this device's, else the server's. Returns one word per
/// line, local order first, with a final newline (empty for no words).
String mergeWordList({
  required String? base,
  required String local,
  required String remote,
}) {
  List<String> words(String text) => [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  final l = words(local);
  final r = words(remote);
  final inBase = {for (final w in words(base ?? '')) w.toLowerCase()};
  final inRemote = {for (final w in r) w.toLowerCase()};
  final seen = <String>{};
  final merged = [
    for (final w in l)
      if ((inRemote.contains(w.toLowerCase()) ||
              !inBase.contains(w.toLowerCase())) &&
          seen.add(w.toLowerCase()))
        w,
    for (final w in r)
      if (!inBase.contains(w.toLowerCase()) && seen.add(w.toLowerCase())) w,
  ];
  return merged.isEmpty ? '' : '${merged.join('\n')}\n';
}

/// One key's value in the merge; `present` false drops the key.
({bool present, Object? value}) _pick(
  String key, {
  required Map<String, Object?> local,
  required Map<String, Object?> remote,
  required Map<String, Object?>? base,
  required bool localNewer,
}) {
  final inLocal = local.containsKey(key);
  final inRemote = remote.containsKey(key);
  final mine = (present: inLocal, value: local[key]);
  final theirs = (present: inRemote, value: remote[key]);
  if (_same(mine, theirs)) return mine;
  if (base != null) {
    final agreed = (present: base.containsKey(key), value: base[key]);
    if (_same(mine, agreed)) return theirs;
    if (_same(theirs, agreed)) return mine;
  } else {
    if (!inRemote) return mine;
    if (!inLocal) return theirs;
  }
  return localNewer ? mine : theirs;
}

bool _same(
  ({bool present, Object? value}) a,
  ({bool present, Object? value}) b,
) =>
    a.present == b.present &&
    (!a.present || jsonEncode(a.value) == jsonEncode(b.value));

Map<String, Object?>? _object(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) return null;
    return {
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
  } on FormatException {
    return null;
  }
}

String _encode(Map<String, Object?> json) =>
    '${const JsonEncoder.withIndent('  ').convert(json)}\n';
