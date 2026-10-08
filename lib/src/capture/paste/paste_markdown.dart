/// Paste as Markdown (#531): what a selection copied from a browser becomes
/// in a note — its HTML through the capture's own conversion, and the link
/// to its page when the browser said which page it was.
library;

import 'package:html/parser.dart' as html;
import 'package:niman/src/capture/paste/clipboard_html.dart';
import 'package:niman/src/markdown/from_html/html_markdown.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// What a paste puts in the note.
typedef PasteChoice = ({
  /// The text that goes in.
  String text,

  /// Whether [text] is the clipboard's HTML as Markdown, rather than its
  /// plain text.
  bool markdown,

  /// The page the Markdown links to, when it does.
  Uri? link,
});

/// What Paste as Markdown puts in the note for a clipboard holding [clip]
/// and [plain] text: the HTML as Markdown when there is HTML that says
/// anything, else the plain text; null when there is neither.
PasteChoice? choosePaste({ClipboardHtml? clip, String? plain}) {
  if (clip != null) {
    final markdown = clipboardMarkdown(clip);
    if (markdown != null) {
      return (text: markdown, markdown: true, link: clip.source);
    }
  }
  if (plain == null || plain.isEmpty) return null;
  return (text: plain, markdown: false, link: null);
}

/// [clip]'s HTML as Markdown, or null when it comes to no text.
///
/// Links and pictures written relative to the page are resolved against
/// [ClipboardHtml.source] when there is one. Pictures stay where they are,
/// on the web — a paste downloads nothing — and one that is not on the web
/// (inline `data:`, a `blob:` of the page, a relative address with no page
/// to resolve it against) is left out. With a source, the Markdown ends
/// in a line linking to its page, as a captured quote does.
String? clipboardMarkdown(ClipboardHtml clip) {
  final source = clip.source;
  String resolve(String address) {
    if (source == null) return address;
    try {
      return source.resolve(address).toString();
    } on FormatException {
      return address;
    }
  }

  String? picture(String src) {
    final resolved = Uri.tryParse(resolve(src.trim()));
    if (resolved == null) return null;
    if (!(resolved.isScheme('http') || resolved.isScheme('https'))) {
      return null;
    }
    return resolved.toString();
  }

  final body = HtmlMarkdown(
    picture: picture,
    link: (href) => resolve(href.trim()),
  ).convert(clip.html).markdown.trim();
  if (body.isEmpty) return null;
  if (source == null) return body;
  final label = escapeMarkdownText(_titleOf(clip.html) ?? source.host);
  return '$body\n\n— [$label](<$source>)';
}

/// The document's `<title>`, when the clipboard's HTML has one — most
/// browsers copy a selection without its page's head.
String? _titleOf(String source) {
  if (!source.contains(RegExp('<title', caseSensitive: false))) return null;
  final title = html.parse(source).querySelector('title')?.text.trim();
  if (title == null || title.isEmpty) return null;
  return title.replaceAll(RegExp(r'\s+'), ' ');
}
