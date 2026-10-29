#!/usr/bin/env python3
"""Subsets a static TTF for Maines' fonts/ folder: python3 tools/subset_font.py <in.ttf> <out.ttf>

Keeps the same characters as fonts/firasans/FiraSans-SemiBold.ttf (Latin, Latin-1 and common
punctuation), drops GPOS/GSUB, and turns the GPOS pair kerning into an old-style 'kern' table,
the format WoW's font engine is most likely to read.
"""
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont, newTable
from fontTools.ttLib.tables._k_e_r_n import KernTable_format_0

ROOT = Path(__file__).resolve().parent.parent
REFERENCE = ROOT / "fonts" / "firasans" / "FiraSans-SemiBold.ttf"


def gpos_pairs(font):
    """Every (left, right) -> x-advance adjustment from GPOS PairPos lookups."""
    pairs = {}
    if "GPOS" not in font:
        return pairs
    for lookup in font["GPOS"].table.LookupList.Lookup:
        subtables = lookup.SubTable
        if lookup.LookupType == 9:  # extension
            subtables = [s.ExtSubTable for s in subtables]
        elif lookup.LookupType != 2:
            continue
        for st in subtables:
            if getattr(st, "LookupType", 2) != 2:
                continue
            firsts = st.Coverage.glyphs
            if st.Format == 1:
                for left, pset in zip(firsts, st.PairSet):
                    for rec in pset.PairValueRecord:
                        v = getattr(rec.Value1, "XAdvance", 0) if rec.Value1 else 0
                        if v:
                            pairs.setdefault((left, rec.SecondGlyph), v)
            elif st.Format == 2:
                c1, c2 = st.ClassDef1.classDefs, st.ClassDef2.classDefs
                seconds = {}
                for g in font.getGlyphOrder():
                    seconds.setdefault(c2.get(g, 0), []).append(g)
                for left in firsts:
                    row = st.Class1Record[c1.get(left, 0)]
                    for cls, rec in enumerate(row.Class2Record):
                        v = getattr(rec.Value1, "XAdvance", 0) if rec.Value1 else 0
                        if v:
                            for right in seconds.get(cls, []):
                                pairs.setdefault((left, right), v)
    return pairs


def main(src, dst):
    keep = sorted(TTFont(str(REFERENCE)).getBestCmap())
    font = TTFont(src)
    opts = subset.Options()
    opts.layout_features = ["kern"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=keep)
    sub.subset(font)
    pairs = gpos_pairs(font)
    for tag in ("GPOS", "GSUB", "GDEF"):
        if tag in font:
            del font[tag]
    if pairs:
        kern = newTable("kern")
        kern.version = 0
        table = KernTable_format_0()
        table.version, table.coverage, table.format = 0, 1, 0
        table.kernTable = pairs
        kern.kernTables = [table]
        font["kern"] = kern
    font.save(dst)
    print(f"{dst}: {Path(dst).stat().st_size} bytes, {len(font.getBestCmap())} chars, {len(pairs)} kern pairs")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
