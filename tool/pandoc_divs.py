"""Writes Pandoc's reading of fenced divs into test/fixtures/columns/pandoc-divs.json.

The fixture holds notes with columns (#729) and the shape Pandoc reads them
as, which test/unit/note_columns_pandoc_test.dart holds the block tree to
with no Pandoc around: Pandoc's is the syntax the columns are written in,
so its nesting is the oracle. A case is added by its `markdown` and
`about`; this fills in, or refreshes, every case's `pandoc`.

The shape keeps what the nesting is about and drops the rest:

* `cols[…]` a `columns` div, `col[…]` a `column` (`col40%` with a width),
  any other div's blocks where it stands;
* `P"text"` a paragraph, its white space collapsed; `H2"text"` a heading;
* `L[I[…] …]` a list and its items, `Q[…]` a quote, `Code`, `HR`, `T`.

Usage: python tool/pandoc_divs.py (pandoc on the PATH)
"""

import json
import pathlib
import re
import subprocess

FIXTURE = (
    pathlib.Path(__file__).parent.parent / "test/fixtures/columns/pandoc-divs.json"
)


def inline_text(inlines):
    out = []
    for node in inlines:
        kind = node["t"]
        if kind == "Str":
            out.append(node["c"])
        elif kind in ("Space", "SoftBreak", "LineBreak"):
            out.append(" ")
        elif kind in ("Emph", "Strong", "Strikeout", "Underline", "SmallCaps"):
            out.append(inline_text(node["c"]))
        elif kind == "Code":
            out.append(node["c"][1])
        elif kind in ("Link", "Image", "Span"):
            out.append(inline_text(node["c"][1]))
        elif kind == "Quoted":
            out.append(inline_text(node["c"][1]))
    return re.sub(r"\s+", " ", "".join(out)).strip()


def shape(blocks):
    parts = []
    for block in blocks:
        kind = block["t"]
        if kind in ("Para", "Plain"):
            parts.append('P"%s"' % inline_text(block["c"]))
        elif kind == "Header":
            parts.append('H%d"%s"' % (block["c"][0], inline_text(block["c"][2])))
        elif kind == "BulletList":
            parts.append("L[%s]" % " ".join("I[%s]" % shape(i) for i in block["c"]))
        elif kind == "OrderedList":
            parts.append(
                "L[%s]" % " ".join("I[%s]" % shape(i) for i in block["c"][1])
            )
        elif kind == "BlockQuote":
            parts.append("Q[%s]" % shape(block["c"]))
        elif kind == "CodeBlock":
            parts.append("Code")
        elif kind == "HorizontalRule":
            parts.append("HR")
        elif kind == "Table":
            parts.append("T")
        elif kind == "Div":
            (_, classes, attributes), children = block["c"]
            inner = shape(children)
            if "columns" in classes:
                parts.append("cols[%s]" % inner)
            elif "column" in classes:
                width = dict(attributes).get("width", "")
                share = ""
                if width.endswith("%"):
                    share = "%g%%" % float(width[:-1])
                parts.append("col%s[%s]" % (share, inner))
            elif inner:
                parts.append(inner)
    return " ".join(p for p in parts if p)


def main() -> None:
    cases = json.loads(FIXTURE.read_text(encoding="utf-8"))
    for case in cases:
        ast = subprocess.run(
            ["pandoc", "-f", "markdown-smart", "-t", "json"],
            input=case["markdown"].encode("utf-8"),
            capture_output=True,
            check=True,
        ).stdout
        case["pandoc"] = shape(json.loads(ast)["blocks"])
    FIXTURE.write_text(
        json.dumps(cases, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"{len(cases)} cases written to {FIXTURE}")


if __name__ == "__main__":
    main()
