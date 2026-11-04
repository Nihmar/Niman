/// Equality and hashing for decoded JSON values: the maps and lists of a
/// settings object, compared by what they hold rather than by identity.
library;

/// Deep-compares two (small) JSON values, recursing into maps and lists.
bool jsonDeepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !jsonDeepEquals(b[entry.key], entry.value)) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonDeepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// A stable hash for a (possibly nested) JSON value.
int jsonStableHash(Object? v) {
  if (v is Map<String, Object?>) {
    final keys = v.keys.toList()..sort();
    final parts = <Object?>[];
    for (final key in keys) {
      parts
        ..add(key)
        ..add(jsonStableHash(v[key]));
    }
    return Object.hashAll(parts);
  }
  if (v is List) return Object.hashAll(v);
  return v.hashCode;
}
