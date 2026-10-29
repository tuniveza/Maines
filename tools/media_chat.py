#!/usr/bin/env python3
"""README media for Maines' chat features: tag-anim.gif, phrases.gif, badges.png, badge-send.gif.

Every bit of chat text the addon produces comes from the real add-on code, run offline by
tools/media_chat.lua (through tests/wowmock.lua). This script only draws it in a WoW-like chat
frame. Run from anywhere:  python3 tools/media_chat.py   (needs lua5.1, Pillow)

The chat font: WoW's English chat font is Arial Narrow (Fonts/ARIALN.TTF, ChatFontNormal, 14pt,
with a drop shadow). It isn't shipped here, so Liberation Sans Narrow (tools/fonts/, GPLv2 + font
exception), which has Arial Narrow's exact glyph widths, stands in. Badge rows are fitted to that font's measured glyph
widths by badges.lua's own FitBadgeLines, exactly like the game does against Arial Narrow.
"""
import json
import os
import random
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "media")
LIB_SANS = "/usr/share/fonts/liberation/LiberationSans-Regular.ttf"
NARROW_FONT = os.path.join(ROOT, "tools", "fonts", "LiberationSansNarrow-Regular.ttf")
AGAVE_BOLD = os.path.join(ROOT, "fonts", "agave", "Agave-Bold.ttf")
AGAVE = os.path.join(ROOT, "fonts", "agave", "Agave-Regular.ttf")
NBSP = " "

CHAT_PX = 17          # chat text size in pixels
LINE_H = 20           # chat line spacing

# WoW's default chat colours (ChatTypeInfo)
COL = {
    "GUILD": (64, 255, 64), "PARTY": (170, 170, 255), "SAY": (255, 255, 255),
    "WHISPER": (255, 128, 255), "SYSTEM": (255, 255, 0),
}
CLASS = {"Fizzlebolt": (63, 199, 235), "Thandrel": (198, 155, 109), "Nyxara": (170, 211, 114),
         "Brightwing": (244, 140, 186)}
# Maines' own colours (maines.lua)
INK = (36, 20, 8)
PLATE_BG = (61, 41, 23)
PLATE_TEXT = (245, 232, 199)
PLATE_TEXT_SOFT = (199, 173, 133)
ACCENT = (178, 120, 46)
GOLD = (255, 209, 0)   # WoW's GameFontNormal gold (chat tabs)

STYLE_LABEL = {"brackets": "Bracket cycle", "typewriter": "Typewriter",
               "wave": "Capital wave", "twinkle": "Twinkle", "phrases": "My phrases"}


# ------------------------------------------------------------------ fonts
def narrow_font_path():
    """Liberation Sans Narrow: open, and metric-compatible with Arial Narrow (same glyph widths)."""
    return NARROW_FONT


CHAT_FONT = None
def chat_font():
    global CHAT_FONT
    if CHAT_FONT is None:
        CHAT_FONT = ImageFont.truetype(narrow_font_path(), CHAT_PX, layout_engine=ImageFont.Layout.BASIC)
    return CHAT_FONT


def unescape(s):
    """What WoW shows for a sent line: an escaped pipe "||" displays as one "|"."""
    return s.replace("||", "|")


# ------------------------------------------------------------------ real chat text from the add-on
def measured_widths():
    f = chat_font()
    base = f.getlength("xx")
    syms = [chr(c) for c in range(32, 127)] + [NBSP, "||"]
    rows = []
    for u in syms:
        if u == "\t":
            continue
        w = f.getlength("x" + unescape(u) + "x") - base
        rows.append(f"{u}\t{w:.4f}")
    return "\n".join(rows) + "\n"


def run_addon():
    with tempfile.NamedTemporaryFile("w", suffix=".tsv", delete=False, encoding="utf-8") as t:
        t.write(measured_widths())
    try:
        res = subprocess.run(["lua5.1", os.path.join(ROOT, "tools", "media_chat.lua"), t.name],
                             capture_output=True, text=True, check=True)
    finally:
        os.unlink(t.name)
    return json.loads(res.stdout)


# ------------------------------------------------------------------ drawing helpers
def backdrop(w, h, seed=7):
    """An out-of-focus 'game world' behind the chat frame: dusky, low contrast."""
    rnd = random.Random(seed)
    small = Image.new("RGB", (32, 12), (28, 30, 34))
    d = ImageDraw.Draw(small)
    for x in range(32):
        for y in range(12):
            t = y / 11
            sky = (52 - 20 * t, 62 - 22 * t, 70 - 26 * t)
            ground = (58, 46, 34)
            mix = max(0, min(1, (y - 6) / 4))
            c = [int(sky[i] * (1 - mix) + ground[i] * mix + rnd.uniform(-9, 9)) for i in range(3)]
            d.point((x, y), tuple(c))
    img = small.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(18))
    # vignette
    vig = Image.new("L", (w, h), 0)
    ImageDraw.Draw(vig).ellipse((-w * 0.3, -h * 0.5, w * 1.3, h * 1.5), fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(60))
    dark = Image.new("RGB", (w, h), (10, 10, 12))
    return Image.composite(img, dark, vig)


def shade(base, box, color=(0, 0, 0), alpha=0.55, radius=0):
    over = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(over).rounded_rectangle(box, radius=radius, fill=color + (int(255 * alpha),))
    base.alpha_composite(over)


def text_runs(draw, x, y, runs, font=None, shadow=True):
    """Draws [(text, rgb)] left to right with WoW's 1px drop shadow. Returns the end x."""
    font = font or chat_font()
    for text, col in runs:
        text = unescape(text)
        if shadow:
            draw.text((x + 1, y + 1), text, font=font, fill=(0, 0, 0, 230))
        draw.text((x, y), text, font=font, fill=col + (255,))
        x += font.getlength(text)
    return x


def chat_line_runs(kind, who, msg, target=None):
    """A received/echoed chat line the way WoW prints it, as coloured runs."""
    c = COL[kind]
    name = CLASS.get(who, c)
    if kind == "GUILD":
        return [("[Guild] [", c), (who, name), ("]: " + msg, c)]
    if kind == "PARTY":
        return [("[Party] [", c), (who, name), ("]: " + msg, c)]
    if kind == "SAY":
        return [("[", c), (who, name), ("] says: " + msg, c)]
    if kind == "WHISPER":
        if target:
            return [("To [", c), (target, CLASS.get(target, c)), ("]: " + msg, c)]
        return [("[", c), (who, name), ("] whispers: " + msg, c)]
    return [(msg, c)]


def editbox_prefix(kind, target=None):
    return {"GUILD": "Guild: ", "PARTY": "Party: ", "SAY": "Say: ",
            "WHISPER": f"Tell {target}: "}[kind]


def plate(draw, box, radius=6):
    """Maines' dark walnut plate with a brass edge."""
    draw.rounded_rectangle(box, radius=radius, fill=PLATE_BG + (235,), outline=ACCENT + (255,), width=1)
    x0, y0, x1, y1 = box
    draw.line((x0 + radius, y0 + 1, x1 - radius, y0 + 1), fill=(120, 86, 44, 255))


def keycap(img, x, y, label, pressed):
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(AGAVE_BOLD, 13)
    w = int(f.getlength(label)) + 18
    off = 2 if pressed else 0
    if not pressed:
        d.rounded_rectangle((x, y + 3, x + w, y + 27), radius=5, fill=(20, 14, 8, 255))
    d.rounded_rectangle((x, y + off, x + w, y + 24 + off), radius=5,
                        fill=(ACCENT if pressed else (92, 66, 36)) + (255,), outline=(30, 20, 10, 255))
    d.text((x + 9, y + 5 + off), label, font=f, fill=PLATE_TEXT + (255,))
    return x + w


# ------------------------------------------------------------------ the chat frame
class ChatFrame:
    W, H = 760, 336
    CX0, CY0, CX1 = 16, 80, 744         # chat box left/top/right
    ROWS = 9

    def __init__(self, caption_fn=None):
        self.lines = []             # list of runs
        self.bg = backdrop(self.W, self.H).convert("RGBA")
        self.caption_fn = caption_fn

    @property
    def cy1(self):
        return self.CY0 + 10 + self.ROWS * LINE_H

    def render(self, edit=None, caption=None, keys=None):
        img = self.bg.copy()
        d = ImageDraw.Draw(img)
        # caption plate
        if caption:
            caption(img)
        # tabs
        tf = ImageFont.truetype(LIB_SANS, 12)
        tx = self.CX0
        for i, name in enumerate(["General", "Combat Log", "Guild"]):
            w = int(tf.getlength(name)) + 22
            shade(img, (tx, self.CY0 - 22, tx + w, self.CY0 - 1), alpha=0.62 if i == 0 else 0.35, radius=3)
            d.text((tx + 11, self.CY0 - 18), name, font=tf,
                   fill=(GOLD if i == 0 else (200, 170, 60)) + (255,))
            tx += w + 3
        # chat box
        shade(img, (self.CX0, self.CY0, self.CX1, self.cy1), alpha=0.42)
        visible = self.lines[-self.ROWS:]
        y = self.cy1 - 6 - len(visible) * LINE_H
        for runs in visible:
            text_runs(d, self.CX0 + 8, y, runs)
            y += LINE_H
        # edit box
        ey = self.cy1 + 6
        active = edit is not None and edit.get("active", True)
        shade(img, (self.CX0, ey, self.CX1, ey + 28), alpha=0.75 if active else 0.3, radius=2)
        d.rectangle((self.CX0, ey, self.CX1, ey + 28),
                    outline=(110, 110, 110, 255) if active else (70, 70, 70, 160))
        if active:
            kind = edit["kind"]
            c = COL[kind]
            pre = editbox_prefix(kind, edit.get("target"))
            x = text_runs(d, self.CX0 + 8, ey + 4, [(pre, c), (edit.get("text", ""), c)])
            if edit.get("cursor", True):
                d.line((x + 1, ey + 6, x + 1, ey + 22), fill=(255, 255, 255, 230), width=1)
        if keys:
            keys(img, ey)
        return img


# ------------------------------------------------------------------ GIF writing
class Gif:
    def __init__(self):
        self.frames = []

    def add(self, img, ms):
        if self.frames and self.frames[-1][0].tobytes() == img.tobytes():
            self.frames[-1][1] += ms
        else:
            self.frames.append([img, ms])

    def save(self, path):
        rgb = [f.convert("RGB") for f, _ in self.frames]
        # one shared palette so colours don't shimmer between frames
        sample = Image.new("RGB", (rgb[0].width, rgb[0].height * 4))
        picks = [rgb[i * (len(rgb) - 1) // 3] for i in range(4)]
        for i, p in enumerate(picks):
            sample.paste(p, (0, i * rgb[0].height))
        # plus every text colour faded over the dark chat box, so thin anti-aliased text keeps
        # its hue even when that colour only shows up in a few frames
        keys = list(COL.values()) + list(CLASS.values()) + [PLATE_TEXT, PLATE_TEXT_SOFT, ACCENT, GOLD, INK]
        sw = Image.new("RGB", (len(keys) * 8, 8 * 6))
        sd = ImageDraw.Draw(sw)
        for i, c in enumerate(keys):
            for j, a in enumerate((1.0, 0.8, 0.6, 0.45, 0.3, 0.15)):
                bg = (22, 24, 28)
                sd.rectangle((i * 8, j * 8, i * 8 + 7, j * 8 + 7),
                             fill=tuple(int(c[k] * a + bg[k] * (1 - a)) for k in range(3)))
        sw = sw.resize((rgb[0].width, sw.height * rgb[0].width // sw.width // 2), Image.NEAREST)
        full = Image.new("RGB", (sample.width, sample.height + sw.height))
        full.paste(sample, (0, 0))
        full.paste(sw, (0, sample.height))
        pal = full.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
        q = [im.quantize(palette=pal, dither=Image.Dither.NONE) for im in rgb]
        q[0].save(path, save_all=True, append_images=q[1:], duration=[ms for _, ms in self.frames],
                  loop=0, optimize=False, disposal=1)


def type_into(gif, frame, kind, text, caption=None, target=None, cps=36, keys=None):
    """Typing animation in the edit box, a couple of letters per frame."""
    step = 2
    for i in range(0, len(text) + 1, step):
        gif.add(frame.render(edit={"kind": kind, "text": text[:i], "target": target},
                             caption=caption, keys=keys), int(1000 * step / cps))
    gif.add(frame.render(edit={"kind": kind, "text": text, "target": target},
                         caption=caption, keys=keys), 260)


# ------------------------------------------------------------------ tag-anim.gif
def caption_maker(title, sub, frames=None, current=None):
    """Maines-style plate above the chat: a title, a short note, and (for the animated tag) the
    style's frames from animate.lua with the one the next message uses lit up."""
    def draw(img):
        d = ImageDraw.Draw(img)
        plate(d, (16, 10, 744, 50))
        fb = ImageFont.truetype(AGAVE_BOLD, 15)
        fs = ImageFont.truetype(AGAVE, 11)
        d.text((30, 13), title, font=fb, fill=PLATE_TEXT + (255,))
        d.text((30, 32), sub, font=fs, fill=PLATE_TEXT_SOFT + (255,))
        left_end = 30 + max(fb.getlength(title), fs.getlength(sub)) + 20
        if frames:
            ff = ImageFont.truetype(AGAVE_BOLD, 13)
            n = len(frames)
            while True:
                shown = frames[:n]
                widths = [ff.getlength(t) + 14 for t in shown]
                more = len(frames) > n
                total = sum(widths) + 4 * (n - 1) + (24 if more else 0)
                if 744 - 12 - total >= left_end or n <= 3:
                    break
                n -= 1
            x = 744 - 12 - total
            for i, t in enumerate(shown):
                w = widths[i]
                if i == current:
                    d.rounded_rectangle((x, 19, x + w, 41), radius=4, fill=ACCENT + (255,))
                    d.text((x + 7, 22), t, font=ff, fill=INK + (255,))
                else:
                    d.text((x + 7, 22), t, font=ff, fill=PLATE_TEXT_SOFT + (255,))
                x += w + 4
            if more:
                d.text((x + 4, 22), "...", font=ff, fill=PLATE_TEXT_SOFT + (255,))
    return draw


def make_tag_anim(data):
    alt = data["alt"]
    frame = ChatFrame()
    frame.lines = [
        chat_line_runs("GUILD", "Thandrel", "evening all o/"),
        chat_line_runs("SAY", "Nyxara", "anyone selling ore?"),
    ]
    scenery = {  # replies from other players (not from the add-on), after message n of a style
        ("brackets", 0): chat_line_runs("GUILD", "Thandrel", "me! what key?"),
        ("typewriter", 0): chat_line_runs("GUILD", "Brightwing", "wb Misa"),
        ("twinkle", 0): chat_line_runs("WHISPER", "Thandrel", "here, sent you one"),
    }
    gif = Gif()
    for st in data["anim"]:
        style = st["style"]
        frames = st["frames"]
        for n, m in enumerate(st["sent"]):
            tag = m["sent"][: len(m["sent"]) - len(m["typed"]) - 1]
            cap = caption_maker("Animated tag: " + STYLE_LABEL[style], "one step per message",
                                frames, frames.index(tag) if tag in frames else None)
            kind, target = m["chatType"], m.get("target")
            gif.add(frame.render(edit={"kind": kind, "text": "", "target": target}, caption=cap), 250)
            type_into(gif, frame, kind, m["typed"], caption=cap, target=target)
            if kind == "WHISPER":
                frame.lines.append(chat_line_runs("WHISPER", alt, m["sent"], target=target))
            else:
                frame.lines.append(chat_line_runs(kind, alt, m["sent"]))
            gif.add(frame.render(edit={"kind": kind, "text": "", "target": target, "cursor": False},
                                 caption=cap), 1100)
            if (style, n) in scenery:
                frame.lines.append(scenery[(style, n)])
                gif.add(frame.render(edit={"kind": kind, "text": "", "target": target, "cursor": False},
                                     caption=cap), 500)
        gif.frames[-1][1] += 500
    gif.save(os.path.join(OUT, "tag-anim.gif"))


# ------------------------------------------------------------------ phrases.gif
def make_phrases(data):
    alt = data["alt"]
    steps = data["phraseSteps"]
    frame = ChatFrame()
    frame.lines = [
        chat_line_runs("GUILD", "Thandrel", "last boss down, nice"),
        chat_line_runs("GUILD", "Nyxara", "gg everyone, timed it!"),
        chat_line_runs("GUILD", "Brightwing", "ty for carrying me lol"),
    ]
    phrases = data["phrases"]
    cap = caption_maker("Saved phrases", f"your phrase key puts the next one in the chat box  ({len(phrases)} saved)")

    def keys_fn(label, pressed, note=None):
        def draw(img, ey):
            # the keys, on the right of the caption plate (Ctrl-1 is an example binding)
            y = 15
            x = keycap(img, 548, y, "Ctrl", pressed and label == "CTRL-1")
            ImageDraw.Draw(img).text((x + 5, y + 5), "+", font=ImageFont.truetype(AGAVE_BOLD, 13),
                                     fill=PLATE_TEXT + (255,))
            x = keycap(img, x + 18, y, "1", pressed and label == "CTRL-1")
            keycap(img, x + 22, y, "Enter", pressed and label == "ENTER")
        return draw

    gif = Gif()
    idle = keys_fn(None, False)
    gif.add(frame.render(edit=None, caption=cap, keys=idle), 1200)
    for i, s in enumerate(steps):
        if s["key"] == "CTRL-1":
            gif.add(frame.render(edit={"kind": "GUILD", "text": steps[i - 1]["box"] if i else "",
                                       "active": i > 0}, caption=cap, keys=keys_fn("CTRL-1", True)), 260)
            gif.add(frame.render(edit={"kind": "GUILD", "text": s["box"]}, caption=cap, keys=idle), 1300)
        else:
            gif.add(frame.render(edit={"kind": "GUILD", "text": s["box"]}, caption=cap,
                                 keys=keys_fn("ENTER", True)), 260)
            frame.lines.append(chat_line_runs("GUILD", alt, s["sent"]))
            gif.add(frame.render(edit={"kind": "GUILD", "text": "", "cursor": False}, caption=cap,
                                 keys=idle), 2400)
    gif.save(os.path.join(OUT, "phrases.gif"))


# ------------------------------------------------------------------ badges.png / badge-send.gif
def badge_runs(alt, msg):
    return chat_line_runs("GUILD", alt, msg)


def make_badges_png(data):
    alt = data["alt"]
    badges = data["badges"]
    f = chat_font()
    cols = 2
    pad = 14
    card_w = 0
    for b in badges:
        for ln in b["lines"]:
            w = 0
            for t, _ in badge_runs(alt, ln["msg"]):
                w += f.getlength(unescape(t))
            card_w = max(card_w, int(w) + 2 * 12)
    card_w = max(card_w, 330)
    rows = (len(badges) + cols - 1) // cols
    row_h = []
    for r in range(rows):
        n = max(len(b["lines"]) for b in badges[r * cols:(r + 1) * cols])
        row_h.append(34 + 14 + n * LINE_H + 12)
    W = cols * card_w + (cols + 1) * pad
    H = sum(row_h) + (rows + 1) * pad
    img = backdrop(W, H, seed=3).convert("RGBA")
    d = ImageDraw.Draw(img)
    fb = ImageFont.truetype(AGAVE_BOLD, 14)
    fs = ImageFont.truetype(AGAVE, 12)
    y = pad
    for r in range(rows):
        for c in range(cols):
            i = r * cols + c
            if i >= len(badges):
                break
            b = badges[i]
            x = pad + c * (card_w + pad)
            plate(d, (x, y, x + card_w, y + 28), radius=5)
            d.text((x + 12, y + 5), f"{b['index']}. {b['name']}", font=fb, fill=PLATE_TEXT + (255,))
            note = f"{len(b['lines'])} line{'s' if len(b['lines']) != 1 else ''}"
            d.text((x + card_w - 12 - fs.getlength(note), y + 8), note, font=fs, fill=PLATE_TEXT_SOFT + (255,))
            top = y + 34
            shade(img, (x, top, x + card_w, y + row_h[r]), alpha=0.5)
            ly = top + 8
            for ln in b["lines"]:
                text_runs(d, x + 10, ly, badge_runs(alt, ln["msg"]))
                ly += LINE_H
        y += row_h[r] + pad
    img.convert("RGB").save(os.path.join(OUT, "badges.png"), optimize=True)


def make_badge_send(data, name="Murloc"):
    alt = data["alt"]
    b = next(x for x in data["badges"] if x["name"] == name)
    frame = ChatFrame()
    frame.lines = [
        chat_line_runs("GUILD", "Thandrel", "who's coming to the raid tonight?"),
        chat_line_runs("GUILD", "Nyxara", "me, if the murloc shows up"),
    ]
    cap = caption_maker("Textual Badges", f"{b['name']}: {len(b['lines'])} lines, one chat line per row")
    gif = Gif()
    gif.add(frame.render(edit={"kind": "GUILD", "text": "", "active": False}, caption=cap), 900)
    type_into(gif, frame, "GUILD", b["command"], caption=cap)
    prev_t = 0.0
    for k, ln in enumerate(b["lines"]):
        if k == 0:
            frame.lines.append(badge_runs(alt, ln["msg"]))
            continue
        gif.add(frame.render(edit={"kind": "GUILD", "text": "", "cursor": False}, caption=cap),
                int(round((ln["t"] - prev_t) * 1000)))
        prev_t = ln["t"]
        frame.lines.append(badge_runs(alt, ln["msg"]))
    gif.add(frame.render(edit={"kind": "GUILD", "text": "", "cursor": False}, caption=cap), 2200)
    frame.lines.append(chat_line_runs("GUILD", "Thandrel", "MRGLGLGL"))
    gif.add(frame.render(edit={"kind": "GUILD", "text": "", "cursor": False}, caption=cap), 1800)
    gif.save(os.path.join(OUT, "badge-send.gif"))


def main():
    os.makedirs(OUT, exist_ok=True)
    data = run_addon()
    if not data.get("fitted"):
        sys.exit("badge widths were not applied")
    make_tag_anim(data)
    make_phrases(data)
    make_badges_png(data)
    make_badge_send(data)
    for n in ("tag-anim.gif", "phrases.gif", "badges.png", "badge-send.gif"):
        p = os.path.join(OUT, n)
        print(f"{n}: {os.path.getsize(p) // 1024} KB")


if __name__ == "__main__":
    main()
