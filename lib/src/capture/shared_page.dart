/// What a share from another app is, when it is the web's (#531): a page —
/// its address alone, or a title with it — or a quote — text selected in
/// the browser, with the page it came from. Anything else is plain text,
/// which goes to the quick note as it always has.
library;

/// What a browser shared: a page, or a quote from one.
sealed class WebShare {
  const new(this.url, {this.title});

  /// The page, as shared.
  final Uri url;

  /// Its title, as the browser shared it.
  final String? title;

  /// The page without the text fragment a quote's link carries.
  Uri get pageUrl => withoutTextFragment(url);
}

/// A web page shared, with the title the sender gave it.
final class SharedPage extends WebShare {
  /// The page at [url], titled [title] when the share named it.
  const new(super.url, {super.title});
}

/// Text selected on a web page, shared with the page.
final class SharedQuote extends WebShare {
  /// [quote], from the page at [url], titled [title] when the share named
  /// it.
  const new(this.quote, super.url, {super.title});

  /// The text selected.
  final String quote;
}

final _url = RegExp(r'https?://\S+$');

/// [url] without a `#:~:text=` fragment: the page itself.
Uri withoutTextFragment(Uri url) {
  final fragment = url.fragment;
  final directive = fragment.indexOf(':~:');
  if (directive < 0) return url;
  final kept = fragment.substring(0, directive);
  return kept.isEmpty ? url.removeFragment() : url.replace(fragment: kept);
}

/// What [text] — shared with [subject] — is: a [SharedPage], a
/// [SharedQuote], or null for plain text.
///
/// A lone address, or a title and an address after it, is a page: the
/// share's subject, or one line of its own above the address — text on
/// the address's own line is a message that ends in a link (#640). Text
/// before an address is a quote when the address points at it with a
/// `#:~:text=` fragment (a browser's "share highlight") or the text is in
/// quotation marks.
WebShare? classifyShare(String text, {String? subject}) {
  final trimmed = text.trim();
  final match = _url.firstMatch(trimmed);
  if (match == null) return null;
  final url = Uri.tryParse(match[0]!);
  if (url == null || url.host.isEmpty) return null;
  final before = trimmed.substring(0, match.start).trim();
  final title = _orNull(subject);
  if (before.isEmpty) return SharedPage(url, title: title);
  final quoted = RegExp(r'^["“«„‘].*["”»“’]$', dotAll: true).hasMatch(before);
  if (url.fragment.contains(':~:text=') || quoted) {
    final quote = quoted ? before.substring(1, before.length - 1) : before;
    return SharedQuote(quote.trim(), url, title: title);
  }
  final ownLine =
      !before.contains('\n') &&
      trimmed.substring(before.length, match.start).contains('\n');
  return before == title || ownLine
      ? SharedPage(url, title: title ?? before)
      : null;
}

String? _orNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
