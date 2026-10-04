"""Builds a simple 1024 x 500 feature graphic (store/feature-graphic-simple.png;
the one used on Play is store/feature-graphic.png) from tool/logo-source.png.
Run: python3 tool/make_feature_graphic.py  (needs Pillow with raqm for Kannada)."""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(__file__)
ROOT = os.path.join(HERE, '..')
FLUTTER = os.environ.get('FLUTTER_ROOT', '/opt/flutter-sdk/flutter')
ROBOTO = os.path.join(FLUTTER, 'bin/cache/artifacts/material_fonts')
W, H = 1024, 500
TOP, BOTTOM = (214, 28, 34), (140, 4, 12)
AMBER, WHITE = (255, 196, 0), (255, 255, 255)

img = Image.new('RGB', (W, H))
d = ImageDraw.Draw(img)
for y in range(H):
    t = y / (H - 1)
    d.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))

# Logo artwork (amber pin, envelope, route) without its square background.
logo = Image.open(os.path.join(HERE, 'logo-source.png')).convert('RGB')
side = 470
logo = logo.resize((side, side), Image.LANCZOS)
alpha = logo.getchannel('G').point(lambda v: max(0, min(255, (v - 45) * 255 // 110)))
art = logo.convert('RGBA')
art.putalpha(alpha)
img.paste(art, (W - side - 10, (H - side) // 2 + 10), art)

font = lambda f, s: ImageFont.truetype(f, s)
bold = os.path.join(ROBOTO, 'Roboto-Bold.ttf')
medium = os.path.join(ROBOTO, 'Roboto-Medium.ttf')
kannada = os.path.join(ROOT, 'store', 'fonts', 'NotoSansKannada.ttf')
x = 64
d.text((x, 92), 'Beat Mitra', font=font(bold, 104), fill=WHITE)
kn = font(kannada, 58)
try:
    kn.set_variation_by_axes([700])
except Exception:
    pass
d.text((x + 4, 214), 'ಬೀಟ್ ಮಿತ್ರ', font=kn, fill=AMBER)
tag = font(medium, 31)
d.text((x + 4, 318), 'Find addresses. Plan your route.', font=tag, fill=WHITE)
d.text((x + 4, 358), 'Deliver faster.', font=tag, fill=WHITE)
d.text((x + 4, 418), 'Free  •  Works offline  •  Private', font=font(medium, 23), fill=(255, 225, 160))

out = os.path.join(ROOT, 'store', 'feature-graphic-simple.png')
img.save(out, optimize=True)
print('written', out, os.path.getsize(out), 'bytes')
