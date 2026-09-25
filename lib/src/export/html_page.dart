/// The exported page around a note's body (#24): one file, its style inline,
/// readable in any browser, light or dark as the reader's system is, and
/// laid out for paper when printed (the PDF, #63, is this page printed).
library;

import 'package:niman/src/export/html_text.dart';

/// A whole page titled [title] around [body]; [fontFaces] are the maths
/// fonts, when a formula on it needs them.
String htmlPage({
  required String title,
  required String body,
  String? fontFaces,
  String language = 'en',
}) {
  final fonts = fontFaces == null ? '' : '<style>$fontFaces</style>\n';
  return '<!DOCTYPE html>\n'
      '<html lang="${escapeAttribute(language)}">\n'
      '<head>\n'
      '<meta charset="utf-8">\n'
      '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
      '<meta name="generator" content="Niman">\n'
      '<title>${escapeHtml(title)}</title>\n'
      '<style>$pageStyle</style>\n'
      '$fonts'
      '</head>\n'
      '<body>\n'
      '<article class="note">\n$body</article>\n'
      '</body>\n'
      '</html>\n';
}

/// The page's style: the read view's shapes — a quiet column of text, code
/// and quotes set apart, tags and links in the accent — on the system's
/// own fonts.
const String pageStyle = '''
:root {
  color-scheme: light dark;
  --text: #1f1f1f; --muted: #6b6b6b; --bg: #ffffff; --line: #e3e3e3;
  --code-bg: #f5f5f4; --accent: #3b6fd4; --mark: #fff3a3;
}
@media (prefers-color-scheme: dark) {
  :root {
    --text: #e6e6e6; --muted: #a0a0a0; --bg: #1b1b1b; --line: #3a3a3a;
    --code-bg: #262626; --accent: #8fb0f5; --mark: #6b5a00;
  }
}
html { background: var(--bg); color: var(--text); }
body {
  margin: 0; padding: 2rem 1rem;
  font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans",
    Ubuntu, Cantarell, sans-serif;
}
.note { max-width: 46rem; margin: 0 auto; overflow-wrap: break-word; }
h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 1.6em 0 0.6em; }
h1 { font-size: 1.9em; } h2 { font-size: 1.5em; } h3 { font-size: 1.25em; }
p, ul, ol, table, pre, blockquote, .callout, .math-block { margin: 0 0 1em; }
a { color: var(--accent); }
.wikilink { color: var(--accent); }
a.wikilink { text-decoration: none; border-bottom: 1px solid currentColor; }
.tag { color: var(--accent); }
.embed { color: var(--muted); }
img { max-width: 100%; height: auto; }
mark { background: var(--mark); color: inherit; padding: 0 0.1em; }
code, pre {
  font-family: ui-monospace, "Cascadia Code", "SF Mono", Menlo, Consolas,
    "DejaVu Sans Mono", monospace;
  font-size: 0.9em;
}
:not(pre) > code { background: var(--code-bg); padding: 0.1em 0.3em;
  border-radius: 4px; }
pre { background: var(--code-bg); padding: 0.8em 1em; border-radius: 6px;
  overflow-x: auto; line-height: 1.45; }
blockquote { margin-left: 0; padding-left: 1em;
  border-left: 3px solid var(--line); color: var(--muted); }
hr { border: 0; border-top: 1px solid var(--line); margin: 2em 0; }
table { border-collapse: collapse; display: block; overflow-x: auto; }
th, td { border: 1px solid var(--line); padding: 0.35em 0.7em; }
th { background: var(--code-bg); }
li.task-list-item { list-style: none; }
li.task-list-item input { margin: 0 0.5em 0 -1.4em; }
svg.math { color: inherit; }
.math-block { text-align: center; overflow-x: auto; }
.math-block svg.math { display: inline-block; }
.callout { border-left: 4px solid var(--callout);
  background: color-mix(in srgb, var(--callout) 10%, transparent);
  border-radius: 4px; padding: 0.6em 1em; }
.callout-title { color: var(--callout); font-weight: 600; }
details.callout > summary { cursor: pointer; }
.callout-body > :last-child { margin-bottom: 0; }
.footnotes { font-size: 0.9em; color: var(--muted);
  border-top: 1px solid var(--line); margin-top: 2em; }
.hljs-comment, .hljs-quote { color: #a0a1a7; font-style: italic; }
.hljs-keyword, .hljs-selector-tag, .hljs-doctag { color: #a626a4; }
.hljs-string, .hljs-regexp, .hljs-addition, .hljs-attribute { color: #50a14f; }
.hljs-number, .hljs-literal, .hljs-built_in, .hljs-type { color: #986801; }
.hljs-title, .hljs-section, .hljs-name { color: #4078f2; }
.hljs-variable, .hljs-template-variable, .hljs-attr { color: #e45649; }
.hljs-meta, .hljs-symbol, .hljs-bullet, .hljs-link { color: #0184bb; }
.hljs-deletion { color: #e45649; }
@media (prefers-color-scheme: dark) {
  .hljs-comment, .hljs-quote { color: #7f848e; }
  .hljs-keyword, .hljs-selector-tag, .hljs-doctag { color: #c678dd; }
  .hljs-string, .hljs-regexp, .hljs-addition, .hljs-attribute {
    color: #98c379; }
  .hljs-number, .hljs-literal, .hljs-built_in, .hljs-type { color: #d19a66; }
  .hljs-title, .hljs-section, .hljs-name { color: #61afef; }
  .hljs-variable, .hljs-template-variable, .hljs-attr { color: #e06c75; }
  .hljs-meta, .hljs-symbol, .hljs-bullet, .hljs-link { color: #56b6c2; }
}
@media print {
  :root { --text: #000; --bg: #fff; }
  body { padding: 0; font-size: 11pt; }
  .note { max-width: none; }
  pre, blockquote, .callout, .math-block, table, img { break-inside: avoid; }
  h1, h2, h3, h4, h5, h6 { break-after: avoid; }
  a { color: inherit; }
}
''';
