#!/usr/bin/env python3
"""Build the corpus that proves the Dart normalizer matches cmark's.

Inputs: every expected-HTML of both suites (sampled deterministically), the
reference's own doctests, and edge cases for the branches the suites do not
reach. Outputs: Python's `normalize_html` on each, which is the definition of
correct.

Usage: python3 gen_corpus.py <cm.json> <gfm.json> <out.json>
"""
import json
import sys

sys.path.insert(0, '/tmp/niman-research')
from cmark_normalize_shim import normalize_html  # noqa: E402

EDGE = [
    '<p>a  \t b</p>', '<p>a  \t\nb</p>', ' <p>a  b</p>', '<p>a  b</p> ',
    '\n\t<p>\n\t\ta  b\t\t</p>\n\t', '<i>a  b</i> ', '<br />', '<br/>',
    '<a title="bar" HREF="foo">x</a>', '&forall;&amp;&gt;&lt;&quot;',
    '<PRE>a\n b</PRE>', '<pre>a\n  b</pre>', '<pre><code>a\n b\n</code></pre>',
    '<ul>\n<li>a</li>\n<li>b</li>\n</ul>', '<ul><li>a</li></ul>\n',
    '<div>\n<p>x</p>\n</div>', '<p><em>a</em> <strong>b</strong></p>',
    '<!-- a comment -->', '<!DOCTYPE html>', '<?php echo 1; ?>',
    '<![CDATA[x < y]]>', '<p>&#35;</p>', '<p>&#x22;</p>',
    '<p>&unknownentity;</p>', '<p>&lt;script&gt;</p>',
    '<img src="a b.png" alt="x">', '<a href="a%20b">y</a>',
    '<p>caf\u00e9 \u4e2d\u6587</p>', '<p>a</p>\r\n<p>b</p>',
    '<p>&amp;amp;</p>', '<hr>', '<hr />', '<hr/>',
    '<p>a<br>\nb</p>', '<p>a<br />\nb</p>',
    '<table>\n<tr><td>a</td></tr>\n</table>',
    '<blockquote>\n<p>q</p>\n</blockquote>',
    '<h1>t</h1>\n<p>b</p>', '<ol start="3">\n<li>x</li>\n</ol>',
    '<p title="a&quot;b">x</p>', '<input checked>', '<input checked="">',
    '<p>\u00a0x\u00a0</p>', '<pre>\n</pre>', '<p></p>',
]

def main():
    cm, gfm, out = sys.argv[1], sys.argv[2], sys.argv[3]
    cases = []
    for path in (cm, gfm):
        data = json.load(open(path, encoding='utf-8'))
        # Deterministic sample: enough constructs to cover every branch, small
        # enough to commit. Every 4th example, plus the first 40 of each suite.
        picked = {e['example'] for e in data[:40]}
        picked |= {e['example'] for e in data if e['example'] % 4 == 0}
        for e in data:
            if e['example'] in picked:
                cases.append(e['html'])
    cases.extend(EDGE)
    seen, corpus = set(), []
    for html in cases:
        if html in seen:
            continue
        seen.add(html)
        corpus.append({'html': html, 'normalized': normalize_html(html)})
    json.dump(corpus, open(out, 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print(f'wrote {out}: {len(corpus)} cases')

if __name__ == '__main__':
    main()
