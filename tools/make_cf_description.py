#!/usr/bin/env python3
"""Builds docs/curseforge-description.html from docs/curseforge-description.md.

CurseForge's description editor takes HTML (paste it into the editor's Source view). Headings,
pictures and the short lines under each heading are centred with inline text-align styles,
the form CurseForge's own editor writes. Run from anywhere: python3 tools/make_cf_description.py
"""
import re
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "curseforge-description.md"
OUT = ROOT / "docs" / "curseforge-description.html"
CENTER = ' style="text-align: center;"'


def build(md_text):
    html = markdown.markdown(md_text, extensions=["tables", "fenced_code"])
    # headings
    html = re.sub(r"<h([1-3])>", lambda m: f"<h{m.group(1)}{CENTER}>", html)
    # paragraphs that only hold a picture
    html = re.sub(r"<p>(<img [^>]*>)</p>", lambda m: f"<p{CENTER}>{m.group(1)}</p>", html)
    # tables sit in the middle of the page
    html = html.replace("<table>", '<table align="center" style="margin-left: auto; margin-right: auto;">')
    # the small print at the end
    html = re.sub(r"<p>(<sub>.*?</sub>)</p>", lambda m: f"<p{CENTER}>{m.group(1)}</p>", html)
    return html + "\n"


if __name__ == "__main__":
    OUT.write_text(build(SRC.read_text()))
    print("wrote", OUT.relative_to(ROOT))
