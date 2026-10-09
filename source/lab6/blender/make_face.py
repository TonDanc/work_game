"""Draws the cartoon face texture (face.png) used on the character's head.

The head is UV-mapped spherically: u = 0.5 is the front of the face, v = 0.5 is eye level.
To use your own photo instead, replace face.png with a 1024x512 image whose
face is centred and fills roughly the middle third horizontally.
"""
import os
from PIL import Image, ImageDraw

W, H = 1024, 512
SKIN = (241, 194, 160)
here = os.path.dirname(os.path.abspath(__file__))

img = Image.new("RGB", (W, H), SKIN)
d = ImageDraw.Draw(img)
cx = W // 2

# Eyes (v ~ 0.47 -> slightly above centre in image space, image y grows downward)
ey = int(H * 0.47)
for dx in (-58, 58):
    d.ellipse([cx + dx - 26, ey - 30, cx + dx + 26, ey + 30], fill=(255, 255, 255), outline=(40, 30, 30), width=4)
    d.ellipse([cx + dx - 15, ey - 14, cx + dx + 15, ey + 20], fill=(60, 40, 30))
    d.ellipse([cx + dx - 6, ey - 8, cx + dx + 4, ey + 2], fill=(255, 255, 255))
# Eyebrows
for dx in (-58, 58):
    d.line([cx + dx - 28, ey - 50, cx + dx + 28, ey - 54 + (8 if dx > 0 else 0)], fill=(55, 35, 25), width=9)
# Nose
d.line([cx, ey + 10, cx - 8, ey + 52, cx + 6, ey + 56], fill=(200, 140, 110), width=5)
# Smile
d.arc([cx - 50, ey + 50, cx + 50, ey + 115], 15, 165, fill=(150, 50, 50), width=7)
# Blush
for dx in (-95, 95):
    d.ellipse([cx + dx - 24, ey + 40, cx + dx + 24, ey + 64], fill=(240, 160, 150))

img.save(os.path.join(here, "face.png"))
print("face.png written")
