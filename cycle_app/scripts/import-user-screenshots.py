"""Import screenshots from Desktop/اب لهب and crop to 390x844 PNG."""
from pathlib import Path
from PIL import Image

SRC = Path.home() / "OneDrive" / "Desktop" / "اب لهب"
OUT = Path(__file__).resolve().parent.parent / "public" / "images" / "screenshots"
TARGET = (390, 844)

MAP = {
    "home.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٤-٣٣-٦٤٩_com.lune.app.jpg",
    "calendar.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٥-٤٨-٣٧٨_com.lune.app.jpg",
    "log.png": "Screenshot_٢٠٢٦-٠٧-٠٧-١٤-٠١-٥٠-٢٤٨_com.lune.app.jpg",
    "goals.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٣-٥٦-٠٨٧_com.lune.app.jpg",
    "ai.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٣-١٤-٤٢١_com.lune.app.jpg",
    "analytics.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٦-٣٤-٩٨٦_com.lune.app.jpg",
    "reports.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٦-٣١-٧٧٥_com.lune.app.jpg",
    "doctor-report.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٦-٥٣-٠٣٩_com.lune.app.jpg",
    "self-care.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٢١-٣٤٤_com.lune.app.jpg",
    "pregnancy.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٠١-٧٢٥_com.lune.app.jpg",
    "community.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-١٠-٠٠١_com.lune.app.jpg",
    "magazine.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٦-١٣-٢٧٣_com.lune.app.jpg",
    "premium.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٢٨-١٥١_com.lune.app.jpg",
    "partner.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٦-١٨-٠٠١_com.lune.app.jpg",
    "privacy.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٩-٥٧-١٣٤_com.lune.app.jpg",
    "stealth.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٩-٥٧-١٣٤_com.lune.app.jpg",
    "reminders.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٥٦-٢٨-٧٤٩_com.lune.app.jpg",
    "wellness-hub.png": "Screenshot_٢٠٢٦-٠٧-٠٨-٢٢-٢٢-٥٥-٠١٧_com.lune.app.jpg",
}


def crop_phone(img: Image.Image) -> Image.Image:
    w, h = img.size
    target_ratio = TARGET[0] / TARGET[1]
    current = w / h
    if current > target_ratio:
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        box = (left, 0, left + new_w, h)
    else:
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        box = (0, top, w, top + new_h)
    cropped = img.crop(box)
    return cropped.resize(TARGET, Image.Resampling.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for png, jpg in MAP.items():
        src = SRC / jpg
        if not src.exists():
            raise FileNotFoundError(src)
        img = Image.open(src).convert("RGB")
        out = crop_phone(img)
        dest = OUT / png
        out.save(dest, "PNG", optimize=True)
        print(f"OK {png} <- {jpg} ({dest.stat().st_size} bytes)")

    for f in OUT.glob("_*"):
        if f.is_file():
            f.unlink()
            print(f"Removed {f.name}")

    print(f"Done — {len(MAP)} screenshots ready.")


if __name__ == "__main__":
    main()
