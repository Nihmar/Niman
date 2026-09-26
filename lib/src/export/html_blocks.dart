/// The blocks an exported page draws itself (#24), as the read view does:
/// a fence with its colours, a formula, a raw HTML block shown as source,
/// and a callout's frame.
library;

import 'package:highlight/highlight.dart' show highlight;
import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/render/callout_style.dart';
import 'package:niman/src/markdown/render/math_text.dart' show displayTexOf;

/// A fence's opening line: its indent, its run and its info string.
final RegExp _opening = RegExp(r'^( {0,3})(`{3,}|~{3,})(.*)$');

/// A fenced code block's [lines], the fences included, as a coloured
/// `<pre>`: coloured by the language its info string names, as the read
/// view colours it, and plain when the grammar does not know it.
String fencedCodeHtml(List<String> lines) {
  final open = lines.isEmpty ? null : _opening.firstMatch(lines.first);
  if (open == null) return _pre(lines.join('\n'), 'code');
  final indent = open.group(1)!.length;
  final fence = open.group(2)!;
  final language = open.group(3)!.trim().split(RegExp(r'\s+')).first;
  var body = lines.skip(1).toList();
  final closing = RegExp(
    '^ {0,3}${RegExp.escape(fence[0])}{${fence.length},}'
    r'\s*$',
  );
  if (body.isNotEmpty && closing.hasMatch(body.last)) {
    body = body.sublist(0, body.length - 1);
  }
  // The fence's own indent comes off every line of its code, as far as
  // the line has it (CommonMark 4.5).
  final code = [for (final line in body) _dedent(line, indent)].join('\n');
  final coloured = _highlighted(code, language);
  final cls = language.isEmpty ? 'hljs' : 'hljs language-$language';
  return '<pre class="code"><code class="${escapeAttribute(cls)}">'
      '${coloured ?? escapeHtml(code)}</code></pre>';
}

/// A math block's [text], `$$` and all, as a centred formula; its source
/// when the TeX does not parse.
String mathBlockHtml(String text, MathSvg math) {
  final tex = displayTexOf(text);
  final svg = math.render(tex, display: true);
  if (svg == null) return _pre(text, 'math-source');
  return '<div class="math-block">$svg</div>';
}

/// A raw HTML block, shown as the source it is: the read view draws it
/// that way, and a page that ran a note's HTML would be doing what the
/// note never did in the app.
String htmlSourceHtml(String text) => _pre(text, 'html-source');

/// A callout's frame around [bodyHtml], in its type's colour: a folding
/// one as `<details>`, open as the note says it starts.
String calloutHtml(Callout callout, String bodyHtml) {
  final argb = calloutStyleOf(callout.type).color.toARGB32();
  final hex = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final attrs =
      'data-callout="${escapeAttribute(callout.type)}" '
      'style="--callout:#$hex"';
  final title = escapeHtml(callout.title);
  final body = bodyHtml.trim().isEmpty
      ? ''
      : '<div class="callout-body">$bodyHtml</div>';
  final summary = '<summary class="callout-title">$title</summary>';
  return switch (callout.fold) {
    CalloutFold.none =>
      '<div class="callout" $attrs><div class="callout-title">$title</div>'
          '$body</div>',
    CalloutFold.open =>
      '<details class="callout" $attrs open="open">$summary$body'
          '</details>',
    CalloutFold.closed =>
      '<details class="callout" $attrs>$summary$body'
          '</details>',
  };
}

String _pre(String text, String cls) =>
    '<pre class="$cls"><code>${escapeHtml(text)}</code></pre>';

String _dedent(String line, int indent) {
  var column = 0;
  var at = 0;
  while (column < indent && at < line.length) {
    final char = line.codeUnitAt(at);
    if (char == 0x20) {
      column++;
      at++;
    } else if (char == 0x09) {
      // A tab advances to the next multiple of four, as CommonMark
      // counts indentation.
      column = (column ~/ 4 + 1) * 4;
      at++;
    } else {
      break;
    }
  }
  // A tab that reached past the fence's indent is partly that indent and
  // partly code: the columns past it stay, as spaces.
  final extra = column > indent ? column - indent : 0;
  return '${' ' * extra}${line.substring(at)}';
}

/// [code] coloured by [language]'s grammar, or null when there is none.
String? _highlighted(String code, String language) {
  if (language.isEmpty) return null;
  try {
    return highlight.parse(code, language: language.toLowerCase()).toHtml();
  } on Object {
    // An unknown language is plain code, as in the read view.
    return null;
  }
}
