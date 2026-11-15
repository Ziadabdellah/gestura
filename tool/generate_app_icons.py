import json
import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "apps" / "gestura"
SDK_FONTS = ROOT / ".fvm" / "flutter_sdk" / "bin" / "cache" / "artifacts" / "material_fonts"
ICON_FONT = SDK_FONTS / "MaterialIcons-Regular.otf"
LABEL_FONT = ROOT / "packages" / "gestura_ui" / "assets" / "fonts" / "ReadexPro-Bold.ttf"

WAVING_HAND = chr(0xF03B5)
LAGOON_LIGHT = (21, 135, 127)
LAGOON = (11, 110, 105)
LAGOON_DEEP = (8, 85, 80)
PAPER = (248, 246, 241)
LAGOON_ON_DARK = (98, 211, 198)
NIGHT = (14, 21, 23)
CORAL = (232, 96, 63)
SUN = (255, 193, 69)
INK = (20, 34, 43)

FLAVORS = {
    "prod": None,
    "dev": ("DEV", CORAL, (255, 255, 255)),
    "staging": ("STG", SUN, INK),
}

ANDROID_DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
WORK = 2048


def gradient(size, steps=256):
    image = Image.new("RGB", (steps, steps))
    pixels = image.load()
    for y in range(steps):
        for x in range(steps):
            t = (x + y) / (2 * (steps - 1))
            if t < 0.5:
                a, b, k = LAGOON_LIGHT, LAGOON, t / 0.5
            else:
                a, b, k = LAGOON, LAGOON_DEEP, (t - 0.5) / 0.5
            pixels[x, y] = tuple(round(a[i] + (b[i] - a[i]) * k) for i in range(3))
    return image.resize((size, size), Image.BICUBIC)


def glyph_mask(size, scale, center_y):
    mask = Image.new("L", (size, size), 0)
    font = ImageFont.truetype(str(ICON_FONT), round(size * scale))
    draw = ImageDraw.Draw(mask)
    left, top, right, bottom = draw.textbbox((0, 0), WAVING_HAND, font=font)
    x = (size - (right - left)) / 2 - left
    y = size * center_y - (bottom - top) / 2 - top
    draw.text((x, y), WAVING_HAND, font=font, fill=255)
    return mask


def badge_layer(size, badge, center_y, width_ratio):
    label, fill, ink = badge
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    width = size * width_ratio
    height = width * 0.42
    left = (size - width) / 2
    top = size * center_y - height / 2
    draw.rounded_rectangle(
        (left, top, left + width, top + height),
        radius=height / 2,
        fill=fill + (255,),
    )
    font = ImageFont.truetype(str(LABEL_FONT), round(height * 0.62))
    bbox = draw.textbbox((0, 0), label, font=font)
    text_x = left + (width - (bbox[2] - bbox[0])) / 2 - bbox[0]
    text_y = top + (height - (bbox[3] - bbox[1])) / 2 - bbox[1]
    draw.text((text_x, text_y), label, font=font, fill=ink + (255,))
    return layer


def soft_shadow(mask, size):
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = ImageChops.offset(mask, 0, round(size * 0.012))
    blurred = offset.filter(ImageFilter.GaussianBlur(size * 0.018))
    shadow.putalpha(blurred.point(lambda v: v * 0.28))
    return shadow


def foreground(size, badge, scale, hand_y, badge_y, badge_width, color=PAPER):
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = glyph_mask(size, scale, hand_y if badge else hand_y + 0.04)
    layer.alpha_composite(soft_shadow(mask, size))
    hand = Image.new("RGBA", (size, size), color + (255,))
    hand.putalpha(mask)
    layer.alpha_composite(hand)
    if badge:
        layer.alpha_composite(badge_layer(size, badge, badge_y, badge_width))
    return layer


def full_icon(badge):
    canvas = gradient(WORK).convert("RGBA")
    canvas.alpha_composite(foreground(WORK, badge, 0.6, 0.44, 0.8, 0.36))
    return canvas


def rounded(image, radius_ratio=0.22):
    size = image.size[0]
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=size * radius_ratio, fill=255
    )
    result = image.copy()
    result.putalpha(mask)
    return result


def save(image, path, size, mode="RGBA"):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).convert(mode).save(path, optimize=True)


def android(flavor, badge):
    res = APP / "android" / "app" / "src" / ("main" if flavor == "prod" else flavor) / "res"
    legacy = rounded(full_icon(badge))
    adaptive_foreground = foreground(WORK, badge, 0.46, 0.45, 0.73, 0.27)
    background = gradient(WORK)
    monochrome = Image.new("RGBA", (WORK, WORK), (255, 255, 255, 0))
    monochrome.putalpha(glyph_mask(WORK, 0.46, 0.49))
    for density, factor in ANDROID_DENSITIES.items():
        folder = res / f"mipmap-{density}"
        save(legacy, folder / "ic_launcher.png", round(48 * factor))
        save(adaptive_foreground, folder / "ic_launcher_foreground.png", round(108 * factor))
        save(background, folder / "ic_launcher_background.png", round(108 * factor), "RGB")
        save(monochrome, folder / "ic_launcher_monochrome.png", round(108 * factor))
    splash = rounded(full_icon(badge))
    for density, factor in ANDROID_DENSITIES.items():
        save(splash, res / f"drawable-{density}" / "splash_mark.png", round(112 * factor))
    if flavor == "prod":
        anydpi = res / "mipmap-anydpi-v26"
        anydpi.mkdir(parents=True, exist_ok=True)
        (anydpi / "ic_launcher.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
            "</adaptive-icon>\n"
        )


def ios(flavor, badge):
    name = "AppIcon" if flavor == "prod" else f"AppIcon-{flavor}"
    folder = APP / "ios" / "Runner" / "Assets.xcassets" / f"{name}.appiconset"
    if folder.exists():
        for old in folder.iterdir():
            old.unlink()
    folder.mkdir(parents=True, exist_ok=True)
    save(full_icon(badge), folder / "Icon.png", 1024, "RGB")
    dark = Image.new("RGBA", (WORK, WORK), (0, 0, 0, 0))
    dark.alpha_composite(foreground(WORK, badge, 0.6, 0.44, 0.8, 0.36, LAGOON_ON_DARK))
    save(dark, folder / "Icon-dark.png", 1024)
    tinted = Image.new("RGB", (WORK, WORK), (0, 0, 0))
    tinted.paste((255, 255, 255), mask=glyph_mask(WORK, 0.6, 0.44 if badge else 0.48))
    save(tinted, folder / "Icon-tinted.png", 1024, "L")
    image = {"idiom": "universal", "platform": "ios", "size": "1024x1024"}
    contents = {
        "images": [
            {**image, "filename": "Icon.png"},
            {
                **image,
                "filename": "Icon-dark.png",
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
            },
            {
                **image,
                "filename": "Icon-tinted.png",
                "appearances": [{"appearance": "luminosity", "value": "tinted"}],
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def ios_launch_image():
    folder = APP / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    mark = rounded(full_icon(None))
    for scale, suffix in ((1, ""), (2, "@2x"), (3, "@3x")):
        save(mark, folder / f"LaunchImage{suffix}.png", 112 * scale)


def feature_graphic():
    width, height = 1024, 500
    side = max(width, height)
    canvas = gradient(side).resize((side, side), Image.LANCZOS).crop((0, (side - height) // 2, width, (side + height) // 2)).convert("RGBA")
    icon = rounded(full_icon(None)).resize((300, 300), Image.LANCZOS)
    shadow = Image.new("RGBA", (340, 340), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((20, 28, 320, 328), radius=66, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(shadow, (60, 80))
    canvas.alpha_composite(icon, (80, 100))
    draw = ImageDraw.Draw(canvas)
    draw.text((440, 150), "Gestura", font=ImageFont.truetype(str(LABEL_FONT), 104), fill=PAPER)
    draw.text((446, 290), "Sign language, in your hands.", font=ImageFont.truetype(str(LABEL_FONT), 32), fill=(214, 240, 236))
    return canvas.convert("RGB")


def store():
    folder = APP / "store"
    folder.mkdir(parents=True, exist_ok=True)
    save(full_icon(None), folder / "play_icon_512.png", 512, "RGB")
    feature_graphic().save(folder / "feature_graphic.png", optimize=True)


def main():
    missing = [path for path in (ICON_FONT, LABEL_FONT) if not path.exists()]
    if missing:
        sys.exit(f"Missing fonts: {missing}. Run fvm install first.")
    for flavor, badge in FLAVORS.items():
        android(flavor, badge)
        ios(flavor, badge)
    ios_launch_image()
    store()


if __name__ == "__main__":
    main()
