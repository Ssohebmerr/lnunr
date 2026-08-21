"""Generate calm atmospheric magazine guide covers (PNG + WebP)."""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "public" / "images" / "magazine" / "guides"
W, H = 1200, 800

# Soft editorial palettes: (bg_top, bg_bottom, accent, accent2)
PALETTES = {
    "cycle-phases": ((245, 232, 228), (214, 196, 210), (180, 140, 160), (230, 210, 200)),
    "spotting": ((248, 236, 232), (220, 180, 178), (190, 120, 130), (240, 220, 215)),
    "symptom-diary": ((236, 240, 245), (200, 210, 225), (140, 160, 190), (220, 228, 238)),
    "privacy-tracking": ((232, 234, 240), (180, 185, 200), (110, 120, 145), (210, 215, 228)),
    "lab-results": ((238, 242, 236), (190, 210, 200), (120, 150, 140), (220, 230, 224)),
    "ovarian-cysts": ((244, 236, 242), (210, 185, 205), (160, 120, 155), (230, 215, 225)),
    "pelvic-pain": ((246, 234, 230), (210, 175, 170), (170, 110, 115), (235, 215, 210)),
    "vaginal-health": ((240, 244, 238), (195, 215, 200), (130, 165, 145), (225, 235, 228)),
    "migraine": ((234, 236, 245), (175, 180, 210), (120, 125, 170), (215, 218, 235)),
    "anemia": ((246, 232, 232), (210, 160, 165), (170, 90, 100), (235, 210, 210)),
    "endo-care": ((244, 230, 236), (205, 160, 180), (165, 100, 130), (230, 205, 215)),
    "intermenstrual": ((245, 235, 230), (215, 185, 175), (175, 125, 120), (235, 220, 215)),
    "amenorrhea": ((238, 236, 242), (195, 190, 210), (145, 140, 170), (225, 222, 235)),
    "breast-pain": ((246, 234, 238), (215, 180, 190), (175, 120, 140), (235, 215, 222)),
    "emergency-care": ((245, 236, 232), (220, 175, 165), (180, 100, 95), (235, 215, 208)),
    "calcium-bones": ((242, 240, 235), (205, 200, 185), (150, 145, 125), (228, 225, 215)),
    "hydration": ((230, 242, 245), (170, 205, 220), (100, 155, 180), (210, 230, 238)),
    "diabetes-hormones": ((240, 242, 235), (190, 205, 185), (130, 155, 130), (225, 232, 220)),
    "caffeine-mood": ((245, 238, 230), (210, 185, 160), (160, 125, 95), (235, 222, 210)),
    "meals-pain": ((244, 240, 232), (210, 195, 165), (165, 140, 100), (232, 225, 210)),
    "anxiety-cycle": ((236, 234, 245), (185, 180, 215), (130, 125, 175), (220, 218, 235)),
    "body-image": ((244, 236, 240), (210, 185, 200), (165, 130, 155), (232, 218, 228)),
    "partner-support": ((240, 236, 242), (200, 185, 210), (150, 130, 170), (228, 220, 235)),
    "fatigue-mood": ((238, 236, 232), (195, 190, 180), (145, 140, 130), (225, 222, 215)),
    "calming-practices": ((232, 240, 238), (175, 205, 200), (110, 155, 150), (215, 230, 226)),
    "strength-cycle": ((236, 238, 242), (175, 185, 205), (115, 130, 160), (218, 222, 232)),
    "yoga-cycle": ((236, 242, 238), (180, 210, 195), (115, 160, 140), (220, 232, 225)),
    "postpartum-movement": ((244, 236, 232), (215, 190, 180), (170, 135, 125), (232, 220, 215)),
    "exercise-pcos": ((238, 240, 245), (185, 195, 220), (125, 140, 175), (222, 226, 238)),
    "active-recovery": ((234, 242, 240), (180, 210, 205), (115, 160, 155), (218, 232, 228)),
    "ttc-six-months": ((246, 236, 240), (215, 185, 200), (175, 130, 155), (235, 218, 228)),
    "early-loss": ((240, 236, 238), (200, 185, 195), (155, 135, 150), (228, 220, 225)),
    "fertility-tests": ((236, 240, 244), (185, 200, 215), (125, 150, 175), (220, 228, 235)),
    "fam-limits": ((242, 236, 242), (205, 185, 210), (160, 130, 170), (230, 218, 232)),
    "early-pregnancy": ((246, 238, 236), (215, 190, 185), (175, 140, 135), (235, 222, 218)),
    "breastfeeding-fertility": ((244, 236, 232), (210, 185, 175), (165, 130, 120), (232, 218, 212)),
    "pain-sex": ((244, 234, 238), (210, 175, 190), (165, 115, 140), (232, 215, 225)),
    "discharge-sex": ((238, 242, 240), (190, 210, 205), (135, 165, 155), (222, 232, 228)),
    "contraception-desire": ((240, 236, 244), (195, 180, 215), (145, 125, 175), (228, 220, 235)),
    "desire-boundaries": ((242, 234, 240), (205, 175, 200), (160, 120, 155), (230, 215, 228)),
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_cover(name: str, palette: tuple) -> Image.Image:
    rng = random.Random(hash(name) & 0xFFFFFFFF)
    top, bottom, accent, accent2 = palette
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        # gentle diagonal bias
        for x in range(W):
            u = (x / (W - 1)) * 0.25
            c = lerp(top, bottom, min(1.0, t + u * 0.15))
            # soft grain
            n = rng.randint(-6, 6)
            px[x, y] = tuple(max(0, min(255, c[i] + n)) for i in range(3))

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Soft light orbs (atmospheric, no faces/text)
    for _ in range(4):
        cx = rng.randint(-100, W + 100)
        cy = rng.randint(-80, H + 80)
        r = rng.randint(180, 420)
        col = accent + (rng.randint(28, 55),)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col)

    for _ in range(3):
        cx = rng.randint(0, W)
        cy = rng.randint(0, H)
        r = rng.randint(80, 220)
        col = accent2 + (rng.randint(35, 70),)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=col)

    # Soft horizontal band for depth
    band_y = int(H * (0.45 + rng.random() * 0.2))
    band_h = rng.randint(60, 140)
    band = Image.new("RGBA", (W, band_h), accent2 + (40,))
    overlay.paste(band, (0, band_y), band)

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=55))
    base = img.convert("RGBA")
    composed = Image.alpha_composite(base, overlay).convert("RGB")
    # Final gentle blur for photographic softness
    composed = composed.filter(ImageFilter.GaussianBlur(radius=1.2))
    return composed


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    existing = {p.stem for p in OUT.glob("*.webp")}
    created = 0
    for name, palette in PALETTES.items():
        png_path = OUT / f"{name}.png"
        webp_path = OUT / f"{name}.webp"
        if webp_path.exists() and png_path.exists():
            continue
        img = make_cover(name, palette)
        img.save(png_path, "PNG", optimize=True)
        img.save(webp_path, "WEBP", quality=82, method=6)
        created += 1
        print(f"created {name}")
    print(f"done created={created} existing_webp={len(existing)}")


if __name__ == "__main__":
    main()
