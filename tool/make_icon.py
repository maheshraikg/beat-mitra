"""Draws the Beat Mitra launcher icon (white envelope + amber location pin on red).
Run: python3 tool/make_icon.py  (needs Pillow)."""
import os
from PIL import Image, ImageDraw

RED = (198, 40, 40, 255)
AMBER = (255, 179, 0, 255)
WHITE = (255, 255, 255, 255)
RES = os.path.join(os.path.dirname(__file__), '..', 'android', 'app', 'src', 'main', 'res')
S = 1024  # draw large, then downscale


def foreground(scale=1.0):
    """Envelope + pin on transparent canvas; artwork fills `scale` of the canvas."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    w = S * 0.62 * scale
    h = w * 0.66
    x0, y0 = c - w / 2, c - h / 2 + S * 0.06 * scale
    x1, y1 = x0 + w, y0 + h
    r = w * 0.07
    d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=WHITE)
    lw = int(w * 0.055)
    d.line([(x0 + r * 0.6, y0 + r * 0.6), (c, y0 + h * 0.55), (x1 - r * 0.6, y0 + r * 0.6)], fill=RED, width=lw, joint='curve')
    # Amber map pin, top-right, overlapping the envelope corner.
    pr = w * 0.2
    px, py = x1 - pr * 0.55, y0 - pr * 0.35
    d.polygon([(px - pr * 0.82, py + pr * 0.55), (px + pr * 0.82, py + pr * 0.55), (px, py + pr * 1.9)], fill=AMBER)
    d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=AMBER)
    d.ellipse([px - pr * 0.42, py - pr * 0.42, px + pr * 0.42, py + pr * 0.42], fill=RED)
    return img


def legacy():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([S * 0.04, S * 0.04, S * 0.96, S * 0.96], radius=S * 0.2, fill=RED)
    img.alpha_composite(foreground(1.0))
    return img


sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
leg, fg = legacy(), foreground(0.62)  # adaptive safe zone = inner 66 %
for dpi, px in sizes.items():
    d = os.path.join(RES, f'mipmap-{dpi}')
    os.makedirs(d, exist_ok=True)
    leg.resize((px, px), Image.LANCZOS).save(os.path.join(d, 'ic_launcher.png'))
    fg.resize((px * 9 // 4, px * 9 // 4), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'))
v26 = os.path.join(RES, 'mipmap-anydpi-v26')
os.makedirs(v26, exist_ok=True)
with open(os.path.join(v26, 'ic_launcher.xml'), 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
with open(os.path.join(RES, 'values', 'ic_launcher_background.xml'), 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#C62828</color>
</resources>
''')
leg.resize((512, 512), Image.LANCZOS).save(os.path.join(os.path.dirname(__file__), 'icon-512.png'))
print('icons written')
