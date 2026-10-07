"""Renders Markdown with cmark-gfm itself, for tool/cmark_harness.dart.

The reference our reading is held to (docs/dev/block-tree.md): GitHub's
cmark-gfm, through its Python binding (`uv run --with cmarkgfm`), with the
extensions GitHub runs — tables, strikethrough, autolinks, the tag filter,
task lists — and footnotes.

Reads one JSON string a line on stdin, the Markdown; writes one JSON
string a line on stdout, its HTML.
"""

import json
import sys

import cmarkgfm
from cmarkgfm.cmark import Options


def main() -> None:
    options = Options.CMARK_OPT_FOOTNOTES | Options.CMARK_OPT_UNSAFE
    for line in sys.stdin:
        markdown = json.loads(line)
        html = cmarkgfm.github_flavored_markdown_to_html(markdown, options)
        sys.stdout.write(json.dumps(html) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
