#!/usr/bin/env python3
"""Extract the GFM spec examples from GitHub's published HTML.

GitHub Flavored Markdown serves no `spec.json` (the URL 404s), so the examples
have to come out of the published HTML. This reads that HTML, attaches each
example to the section heading above it, and writes the same JSON shape the
CommonMark suite uses.

Two conventions from the spec's own runner (`cmark-gfm`'s `spec_tests.py`,
`test/spec_tests.py:109-110`) are reproduced here: the `→` glyph means a
literal tab in *both* the Markdown and the expected HTML, and the HTML side is
entity-encoded inside its `<pre><code>`.

Usage:
  python3 tool/extract_gfm_spec.py gfm.html test/fixtures/spec/gfm-0.29-gfm.json
"""
import html
import json
import re
import sys

HEADING = re.compile(
    r'<h([12])\s+id="[^"]*"[^>]*class="definition">(.*?)</h\1>', re.S)
NUMBER = re.compile(r'<span class="number">([\d.]+)</span>')
EXAMPLE = re.compile(r'<div class="example" id="example-(\d+)">(.*?)\n</div>\n</div>',
                     re.S)
CODE = re.compile(
    r'<pre><code class="language-(markdown|html)">(.*?)</code></pre>', re.S)
SPACE = re.compile(r'<span class="space"> </span>')


def strip_tags(text):
    """The heading's own inline markup, gone; entities decoded."""
    return html.unescape(re.sub(r'<[^>]+>', '', text)).strip()


def main() -> int:
    src, dst = sys.argv[1], sys.argv[2]
    doc = open(src, encoding='utf-8').read()

    # Section = the last <h1>/<h2> seen before the example, as "N.N Title".
    marks = []
    for m in HEADING.finditer(doc):
        number = NUMBER.search(m.group(2))
        # The number is a <span> inside the heading; drop it before the title.
        title = strip_tags(NUMBER.sub('', m.group(2)))
        marks.append((m.start(), f'{number.group(1)} {title}' if number else title))

    def section_at(pos):
        found = None
        for start, name in marks:
            if start < pos:
                found = name
            else:
                break
        return found or 'unknown'

    examples = []
    for m in EXAMPLE.finditer(doc):
        number = int(m.group(1))
        body = m.group(2)
        codes = {kind: SPACE.sub(' ', value) for kind, value in CODE.findall(body)}
        if 'markdown' not in codes or 'html' not in codes:
            print(f'example {number}: missing block, skipped', file=sys.stderr)
            continue
        examples.append({
            'example': number,
            'section': section_at(m.start()),
            'markdown': html.unescape(codes['markdown']).replace('\u2192', '\t'),
            'html': html.unescape(codes['html']).replace('\u2192', '\t'),
        })

    examples.sort(key=lambda e: e['example'])
    ids = [e['example'] for e in examples]
    if ids != list(range(1, len(ids) + 1)):
        print(f'warning: example numbers are not 1..{len(ids)}', file=sys.stderr)

    with open(dst, 'w', encoding='utf-8') as out:
        json.dump(examples, out, ensure_ascii=False, indent=1)
        out.write('\n')

    sections = {}
    for e in examples:
        sections[e['section']] = sections.get(e['section'], 0) + 1
    print(f'wrote {dst}: {len(examples)} examples, {len(sections)} sections')
    for name, count in sections.items():
        print(f'  {count:4d}  {name}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
