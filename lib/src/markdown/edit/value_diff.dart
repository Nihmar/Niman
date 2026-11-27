/// What the platform changed between two copies of the text it holds: the
/// range of the old one that went, and what took its place.
typedef ValueDiff = ({int start, int end, String inserted});

/// The smallest range [ours] and [theirs] differ in, for the platform that
/// reports whole values instead of edits (#1354).
///
/// A keystroke is one edit and one undo step rather than a whole note
/// replaced. A character typed beside an equal one — a `(` typed before
/// another — differs in two places equally well; with the platform's [caret]
/// in [theirs] the insertion is the one that ends at it, which is where it
/// was typed.
ValueDiff diffValues(String ours, String theirs, {int? caret}) {
  var prefix = 0;
  final shortest = ours.length < theirs.length ? ours.length : theirs.length;
  while (prefix < shortest &&
      ours.codeUnitAt(prefix) == theirs.codeUnitAt(prefix)) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < shortest - prefix &&
      ours.codeUnitAt(ours.length - 1 - suffix) ==
          theirs.codeUnitAt(theirs.length - 1 - suffix)) {
    suffix++;
  }
  final added = theirs.length - ours.length;
  if (added > 0 && caret != null) {
    // A pure insertion that ends at the caret, when there is one: the text
    // without it is the old one.
    final at = caret - added;
    if (at >= 0 &&
        caret <= theirs.length &&
        theirs.substring(0, at) + theirs.substring(caret) == ours) {
      return (start: at, end: at, inserted: theirs.substring(at, caret));
    }
  }
  return (
    start: prefix,
    end: ours.length - suffix,
    inserted: theirs.substring(prefix, theirs.length - suffix),
  );
}
