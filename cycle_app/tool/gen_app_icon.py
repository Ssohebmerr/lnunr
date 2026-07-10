"""
Lune — feminine luxe app icon generator.
Renders a crescent-moon + cycle-orbit emblem on a rose->lavender premium gradient.
Supersampled 4x then downscaled (LANCZOS) for crisp anti-aliased edges.

Outputs (1024x1024):
  app_icon.png     full-bleed square master  (iOS + legacy Android)
  app_icon_fg.png  transparent emblem         (Android adaptive foreground)
  app_icon_bg.png  gradient only              (Android adaptive background)

Regenerate everything (from cycle_app/):
  python tool/gen_app_icon.py assets/icon
  dart run flutter_launcher_icons

Requires: pip install pillow numpy
Palette mirrors lib/core/theme/app_design_tokens.dart (AuraColors).
"""
import sys, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
BASE = 1024
SS = 4                      # supersample factor
S = BASE * SS              # working resolution
C = S / 2                  # center

def hx(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

ROSE      = hx('E8A0BF')
ROSE_DEEP = hx('D484A8')
LAVENDER  = hx('C9B8E8')
PEACH     = hx('FFCDB2')
PEACHGOLD = hx('FFB4A2')
CREAM     = hx('FFFBF8')
BLUSH     = hx('FADADD')
PLUM      = hx('5C3D52')

def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))

# ---------------------------------------------------------------- background
def make_background():
    """Diagonal 3-stop premium gradient + soft radial luxe glow."""
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    # diagonal parameter (top-left -> bottom-right)
    t = (xx + yy) / (2 * S)
    stops = [(0.00, PEACH), (0.48, ROSE), (1.00, LAVENDER)]
    r = np.zeros_like(t); g = np.zeros_like(t); b = np.zeros_like(t)
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]; t1, c1 = stops[i + 1]
        m = (t >= t0) & (t <= t1) if i == 0 else (t > t0) & (t <= t1)
        lt = np.clip((t - t0) / (t1 - t0), 0, 1)
        r = np.where(m, c0[0] + (c1[0] - c0[0]) * lt, r)
        g = np.where(m, c0[1] + (c1[1] - c0[1]) * lt, g)
        b = np.where(m, c0[2] + (c1[2] - c0[2]) * lt, b)
    over = t > 1
    r = np.where(over, LAVENDER[0], r); g = np.where(over, LAVENDER[1], g); b = np.where(over, LAVENDER[2], b)

    # soft radial glow (warm light) upper-left of center
    gx, gy = S * 0.36, S * 0.30
    dist = np.sqrt((xx - gx) ** 2 + (yy - gy) ** 2) / (S * 0.62)
    glow = np.clip(1 - dist, 0, 1) ** 2 * 0.35
    r = r + (255 - r) * glow
    g = g + (250 - g) * glow
    b = b + (245 - b) * glow

    arr = np.stack([r, g, b], axis=-1).clip(0, 255).astype(np.uint8)
    return Image.fromarray(arr, 'RGB').convert('RGBA')

# ---------------------------------------------------------------- moon
def vertical_gradient(size, top, bottom):
    yy = np.linspace(0, 1, size)[:, None]
    r = top[0] + (bottom[0] - top[0]) * yy
    g = top[1] + (bottom[1] - top[1]) * yy
    b = top[2] + (bottom[2] - top[2]) * yy
    arr = np.concatenate([np.broadcast_to(r, (size, size))[..., None],
                          np.broadcast_to(g, (size, size))[..., None],
                          np.broadcast_to(b, (size, size))[..., None]], axis=-1)
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8), 'RGB')

def make_moon():
    """Crescent (outer disk minus offset disk) with cream->blush gradient + soft glow.
    Returns an RGBA layer at full S."""
    R = int(S * 0.150)                 # outer moon radius
    mcx, mcy = C - S * 0.010, C - S * 0.006
    cut_off = R * 0.46                  # how far the carving disk is shifted
    R2 = int(R * 0.94)                  # carving disk radius
    ccx = mcx + cut_off                 # carve toward the right -> crescent opens lower-left
    ccy = mcy - cut_off * 0.34

    # crescent mask
    mask = Image.new('L', (S, S), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([mcx - R, mcy - R, mcx + R, mcy + R], fill=255)
    md.ellipse([ccx - R2, ccy - R2, ccx + R2, ccy + R2], fill=0)

    # moon fill = vertical cream->blush gradient
    grad = vertical_gradient(S, CREAM, BLUSH).convert('RGBA')
    moon = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    moon.paste(grad, (0, 0), mask)

    # soft outer glow
    glow_mask = mask.filter(ImageFilter.GaussianBlur(S * 0.020))
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    gcol = Image.new('RGBA', (S, S), CREAM + (255,))
    glow.paste(gcol, (0, 0), glow_mask.point(lambda v: int(v * 0.55)))

    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out = Image.alpha_composite(out, glow)
    out = Image.alpha_composite(out, moon)
    return out

# ---------------------------------------------------------------- orbit + dots + sparkle
def make_orbit():
    """Tilted elliptical cycle-orbit ring with 3 phase dots. RGBA at full S."""
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    # draw ring on an unrotated buffer centered, then rotate
    rx, ry = int(S * 0.300), int(S * 0.270)
    stroke = int(S * 0.0055)
    ring = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse([C - rx, C - ry, C + rx, C + ry], outline=CREAM + (150,), width=stroke)
    ring = ring.rotate(-20, resample=Image.BICUBIC, center=(C, C))
    layer = Image.alpha_composite(layer, ring)

    # phase dots positioned along the tilted orbit
    tilt = math.radians(-20)
    def orbit_point(deg):
        a = math.radians(deg)
        ex, ey = rx * math.cos(a), ry * math.sin(a)
        x = C + ex * math.cos(tilt) - ey * math.sin(tilt)
        y = C + ex * math.sin(tilt) + ey * math.cos(tilt)
        return x, y
    dd = ImageDraw.Draw(layer)
    # bright leading dot (top-right), two soft dots
    dots = [(-38, int(S * 0.019), 255), (150, int(S * 0.013), 170), (95, int(S * 0.010), 130)]
    for deg, rad, alpha in dots:
        x, y = orbit_point(deg)
        # soft halo
        halo = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        hd = ImageDraw.Draw(halo)
        hd.ellipse([x - rad * 2.4, y - rad * 2.4, x + rad * 2.4, y + rad * 2.4], fill=CREAM + (70,))
        halo = halo.filter(ImageFilter.GaussianBlur(S * 0.006))
        layer = Image.alpha_composite(layer, halo)
        dd = ImageDraw.Draw(layer)
        dd.ellipse([x - rad, y - rad, x + rad, y + rad], fill=CREAM + (alpha,))

    # sparkle (4-point star) near the moon's inner glow
    sx, sy = C + S * 0.075, C - S * 0.150
    spk = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(spk)
    L, w = S * 0.045, S * 0.010
    sd.polygon([(sx, sy - L), (sx + w, sy), (sx, sy + L), (sx - w, sy)], fill=CREAM + (235,))
    sd.polygon([(sx - L, sy), (sx, sy - w), (sx + L, sy), (sx, sy + w)], fill=CREAM + (235,))
    glowspk = spk.filter(ImageFilter.GaussianBlur(S * 0.010))
    layer = Image.alpha_composite(layer, glowspk)
    layer = Image.alpha_composite(layer, spk)
    return layer

# ---------------------------------------------------------------- compose
def build_emblem():
    em = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    em = Image.alpha_composite(em, make_orbit())
    em = Image.alpha_composite(em, make_moon())
    # drop a subtle plum shadow beneath the emblem for depth
    shadow_src = em.split()[3].filter(ImageFilter.GaussianBlur(S * 0.02))
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    scol = Image.new('RGBA', (S, S), PLUM + (255,))
    shadow.paste(scol, (0, int(S * 0.012)), shadow_src.point(lambda v: int(v * 0.18)))
    return em, shadow

def down(img):
    return img.resize((BASE, BASE), Image.LANCZOS)

def main():
    bg = make_background()
    emblem, shadow = build_emblem()

    master = Image.alpha_composite(bg, shadow)
    master = Image.alpha_composite(master, emblem)
    down(master.convert('RGB').convert('RGBA')).convert('RGB').save(f"{OUT}/app_icon.png")

    # adaptive foreground: full-bleed emblem — the launcher xml applies a 16%
    # inset, which places the emblem inside the ~66% safe zone automatically.
    fg = Image.alpha_composite(shadow, emblem)
    down(fg).save(f"{OUT}/app_icon_fg.png")

    down(bg).convert('RGB').save(f"{OUT}/app_icon_bg.png")

    # splash logo: emblem recoloured to a rose->plum gradient on transparent,
    # so it reads on a light splash background (flutter_native_splash centers it).
    alpha = emblem.split()[3]
    sgrad = vertical_gradient(S, hx('D07AA0'), hx('5C3D52')).convert('RGBA')
    logo = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    logo.paste(sgrad, (0, 0), alpha)
    sc = 0.66
    ns = int(S * sc)
    logo_s = logo.resize((ns, ns), Image.LANCZOS)
    logo_c = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    o = (S - ns) // 2
    logo_c.paste(logo_s, (o, o), logo_s)
    down(logo_c).save(f"{OUT}/splash_logo.png")

    print("done ->", OUT)

if __name__ == '__main__':
    main()
