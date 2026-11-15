import json
import math
import pathlib
import shutil
import subprocess
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Pillow is required: python3 -m pip install pillow")

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "apps" / "gestura"
PACK = APP / "assets" / "content" / "demo" / "pack.json"
FONT = ROOT / "packages" / "gestura_ui" / "assets" / "fonts" / "ReadexPro-Bold.ttf"

WIDTH, HEIGHT = 480, 600
FPS = 24
STAGE = (16, 28, 33)
ON_STAGE = (255, 255, 255)
LABEL = (255, 156, 130)
HAND = (98, 211, 198)
TRACK = (39, 53, 58)


def font(size):
    return ImageFont.truetype(str(FONT), size)


def centered(draw, text, y, typeface, fill):
    left, top, right, bottom = draw.textbbox((0, 0), text, font=typeface)
    draw.text(((WIDTH - (right - left)) / 2, y), text, font=typeface, fill=fill)


def frame(gloss, progress):
    image = Image.new("RGB", (WIDTH, HEIGHT), STAGE)
    draw = ImageDraw.Draw(image)
    centered(draw, "PLACEHOLDER", 40, font(26), LABEL)
    if len(gloss) == 1:
        centered(draw, gloss, 110, font(140), ON_STAGE)
        centered(draw, "Letter video coming soon", 340, font(20), LABEL)
    else:
        centered(draw, gloss, 250, font(48 if len(gloss) < 10 else 38), ON_STAGE)
        centered(draw, "Sign video coming soon", 320, font(20), LABEL)

    angle = math.pi * (1 - progress)
    x = WIDTH / 2 + 150 * math.cos(angle)
    y = 470 - 70 * math.sin(angle)
    radius = 26
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=HAND)
    draw.polygon([(x + radius + 4, y - 12), (x + radius + 26, y), (x + radius + 4, y + 12)], fill=HAND)

    draw.rounded_rectangle((40, 560, WIDTH - 40, 568), radius=4, fill=TRACK)
    draw.rounded_rectangle((40, 560, 40 + (WIDTH - 80) * progress, 568), radius=4, fill=HAND)
    return image


def encode(gloss, duration_ms, video_path):
    frames = max(2, round(duration_ms / 1000 * FPS))
    command = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-f", "image2pipe", "-framerate", str(FPS), "-i", "-",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-profile:v", "baseline",
        "-crf", "30", "-movflags", "+faststart", "-an", str(video_path),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    for index in range(frames):
        frame(gloss, index / (frames - 1)).save(process.stdin, "PNG")
    process.stdin.close()
    if process.wait() != 0:
        sys.exit(f"ffmpeg failed for {gloss}")


def main():
    if shutil.which("ffmpeg") is None:
        sys.exit("ffmpeg is required")
    catalog = json.loads(PACK.read_text(encoding="utf-8"))
    letters = [dict(letter, gloss=letter["letter"], id=f"letter-{letter['letter'].lower()}") for letter in catalog.get("alphabet", [])]
    for sign in catalog["signs"] + letters:
        video = APP / sign["video"]
        thumbnail = APP / sign["thumbnail"]
        video.parent.mkdir(parents=True, exist_ok=True)
        encode(sign["gloss"], sign["durationMs"], video)
        frame(sign["gloss"], 0.5).resize((240, 300)).save(thumbnail, "WEBP", quality=80)
        print(f"{sign['id']}: {video.stat().st_size // 1024} KB video, {thumbnail.stat().st_size // 1024} KB thumbnail")


if __name__ == "__main__":
    main()
