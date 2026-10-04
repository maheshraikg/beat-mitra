"""Builds the Beat Mitra icons from tool/logo-source.png (square artwork:
amber pin with a white envelope and a dotted route on red).
Writes the Android launcher icons (legacy + adaptive + monochrome) and the
512 px Play Store icon. Run: python3 tool/make_icon.py  (needs Pillow)."""
import os
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(__file__)
RES = os.path.join(HERE, '..', 'android', 'app', 'src', 'main', 'res')
STORE = os.path.join(HERE, '..', 'store')
S = 1024

src = Image.open(os.path.join(HERE, 'logo-source.png')).convert('RGB').resize((S, S), Image.LANCZOS)


def art_mask(img):
    """Alpha of the amber/white artwork: the red background has little green."""
    g = img.getchannel('G')
    return g.point(lambda v: max(0, min(255, (v - 45) * 255 // 110)))


def edge_colour(img):
    """Average colour of the outer border, used behind the adaptive icon."""
    w, h = img.size
    px = [img.getpixel((x, y)) for x in range(0, w, 16) for y in (0, h - 1)]
    px += [img.getpixel((x, y)) for y in range(0, h, 16) for x in (0, w - 1)]
    return tuple(sum(p[i] for p in px) // len(px) for i in range(3))


def legacy():
    """Pre-Android-8 launchers show the PNG as is: rounded square."""
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([S * 0.04, S * 0.04, S * 0.96, S * 0.96], radius=S * 0.2, fill=255)
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    inner = src.resize((int(S * 0.92), int(S * 0.92)), Image.LANCZOS)
    out.paste(inner, (int(S * 0.04), int(S * 0.04)))
    out.putalpha(mask)
    return out


def adaptive_foreground():
    """108 dp layer; the full artwork (with its own background) fills the
    72 dp visible area, so every mask shape shows the whole logo."""
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    side = S * 72 // 108
    out.paste(src.resize((side, side), Image.LANCZOS), ((S - side) // 2, (S - side) // 2))
    return out


def monochrome():
    """Themed-icon layer (Android 13+): artwork shapes only, in the safe zone."""
    side = S * 72 // 108
    art = Image.new('RGBA', (side, side), (255, 255, 255, 0))
    art.putalpha(art_mask(src.resize((side, side), Image.LANCZOS)))
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.alpha_composite(art, ((S - side) // 2, (S - side) // 2))
    return out


sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
leg, fg, mono = legacy(), adaptive_foreground(), monochrome()
for dpi, px in sizes.items():
    d = os.path.join(RES, f'mipmap-{dpi}')
    os.makedirs(d, exist_ok=True)
    leg.resize((px, px), Image.LANCZOS).save(os.path.join(d, 'ic_launcher.png'), optimize=True)
    layer = px * 9 // 4
    fg.resize((layer, layer), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'), optimize=True)
    mono.resize((layer, layer), Image.LANCZOS).save(os.path.join(d, 'ic_launcher_monochrome.png'), optimize=True)
v26 = os.path.join(RES, 'mipmap-anydpi-v26')
os.makedirs(v26, exist_ok=True)
with open(os.path.join(v26, 'ic_launcher.xml'), 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''')
bg = '#%02X%02X%02X' % edge_colour(src)
with open(os.path.join(RES, 'values', 'ic_launcher_background.xml'), 'w') as f:
    f.write(f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{bg}</color>
</resources>
''')
# Play Store icon: 512 x 512, full square (Play rounds the corners itself).
src.resize((512, 512), Image.LANCZOS).save(os.path.join(STORE, 'icon-512.png'), optimize=True)
print('icons written, background', bg)
