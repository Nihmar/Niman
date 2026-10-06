"""Writes cmark-gfm's HTML into test/fixtures/spec/cmark-cases.json.

The fixture holds documents where our reading once parted from cmark-gfm's
(found by tool/cmark_harness.dart), each with the HTML cmark-gfm writes for
it, which test/unit/cmark_cases_test.dart holds `TreeHtml` to with no Python
around. A case is added by its `markdown` and `about`; this fills in, or
refreshes, every case's `html` (`pip install cmarkgfm`).

Usage: python tool/cmark_cases.py
"""

import json
import pathlib

import cmarkgfm
from cmarkgfm.cmark import Options

FIXTURE = pathlib.Path(__file__).parent.parent / "test/fixtures/spec/cmark-cases.json"


def main() -> None:
    options = Options.CMARK_OPT_FOOTNOTES | Options.CMARK_OPT_UNSAFE
    cases = json.loads(FIXTURE.read_text(encoding="utf-8"))
    for case in cases:
        case["html"] = cmarkgfm.github_flavored_markdown_to_html(
            case["markdown"], options
        )
    FIXTURE.write_text(
        json.dumps(cases, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"{len(cases)} cases written to {FIXTURE}")


if __name__ == "__main__":
    main()
