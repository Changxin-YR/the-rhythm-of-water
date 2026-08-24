from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "release-assets" / "WaterReminder-app-icon-1024x1024.png"
APP_SCOPE_MEDIA = ROOT / "AppScope" / "resources" / "base" / "media"
ENTRY_MEDIA = ROOT / "entry" / "src" / "main" / "resources" / "base" / "media"
LISTING_ICON = ROOT / "release-assets" / "WaterReminder-AppGallery-icon-1024x1024.png"
PREVIEW = ROOT / "artifacts" / "icon-layer-preview.png"
SIZE = 1024
AA = 4
SAFE_INSET = 80


def cubic_points(start: tuple[float, float], segments: list[tuple[float, ...]], steps: int = 24) -> list[tuple[float, float]]:
    points = [start]
    x0, y0 = start
    for x1, y1, x2, y2, x3, y3 in segments:
        for index in range(1, steps + 1):
            t = index / steps
            inv = 1 - t
            x = inv**3 * x0 + 3 * inv**2 * t * x1 + 3 * inv * t**2 * x2 + t**3 * x3
            y = inv**3 * y0 + 3 * inv**2 * t * y1 + 3 * inv * t**2 * y2 + t**3 * y3
            points.append((x, y))
        x0, y0 = x3, y3
    return points


def scaled(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(round(x * AA), round(y * AA)) for x, y in points]


def draw_path(draw: ImageDraw.ImageDraw, start: tuple[float, float], segments: list[tuple[float, ...]], fill: int) -> None:
    draw.polygon(scaled(cubic_points(start, segments)), fill=fill)


def build_foreground(reference: Image.Image) -> Image.Image:
    mask_large = Image.new("L", (SIZE * AA, SIZE * AA), 0)
    draw = ImageDraw.Draw(mask_large)

    # Main water-drop silhouette, including the translucent interior behind the glass.
    draw_path(
        draw,
        (505, 92),
        [
            (486, 94, 458, 134, 421, 177),
            (365, 240, 309, 303, 268, 371),
            (231, 433, 212, 503, 212, 566),
            (212, 636, 239, 704, 282, 766),
            (322, 821, 393, 858, 470, 877),
            (541, 894, 620, 858, 682, 799),
            (744, 741, 785, 663, 792, 590),
            (798, 516, 772, 437, 725, 366),
            (669, 281, 591, 184, 535, 113),
            (523, 98, 514, 92, 505, 92),
        ],
        255,
    )

    # Glass and water surface. This widens the lower silhouette where it overlaps the drop.
    draw_path(
        draw,
        (282, 491),
        [
            (294, 474, 332, 469, 365, 473),
            (416, 478, 466, 515, 511, 521),
            (554, 515, 611, 477, 664, 478),
            (689, 478, 705, 485, 709, 496),
            (706, 566, 696, 645, 680, 722),
            (665, 793, 657, 824, 630, 842),
            (589, 868, 521, 877, 450, 867),
            (390, 858, 351, 840, 332, 805),
            (310, 765, 302, 682, 292, 600),
            (286, 546, 279, 508, 282, 491),
        ],
        255,
    )

    # Green leaf and its white highlight outline.
    draw_path(
        draw,
        (504, 893),
        [
            (532, 884, 548, 861, 551, 821),
            (555, 765, 574, 716, 609, 675),
            (643, 637, 693, 620, 739, 596),
            (773, 579, 795, 556, 810, 552),
            (821, 570, 824, 594, 822, 625),
            (819, 682, 795, 738, 753, 784),
            (711, 829, 653, 858, 594, 878),
            (554, 892, 526, 899, 504, 893),
        ],
        255,
    )

    # Two airborne splash droplets.
    draw_path(
        draw,
        (620, 454),
        [
            (615, 439, 589, 423, 588, 400),
            (587, 384, 596, 374, 610, 374),
            (629, 373, 639, 387, 639, 404),
            (639, 421, 631, 440, 620, 454),
        ],
        255,
    )
    draw_path(
        draw,
        (633, 469),
        [
            (645, 448, 661, 431, 677, 428),
            (692, 425, 701, 433, 701, 445),
            (701, 459, 691, 466, 677, 466),
            (660, 465, 645, 466, 633, 469),
        ],
        255,
    )

    mask = mask_large.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    mask = mask.filter(ImageFilter.GaussianBlur(0.35))

    foreground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(shadow_mask).ellipse((230, 828, 818, 925), fill=92)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(23))
    shadow.putalpha(shadow_mask)
    shadow_color = Image.new("RGBA", (SIZE, SIZE), (0, 124, 214, 255))
    foreground = Image.composite(shadow_color, foreground, shadow_mask)

    cutout = reference.copy()
    cutout.putalpha(mask)
    foreground.alpha_composite(cutout)

    bbox = foreground.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Foreground artwork is empty")
    content = foreground.crop(bbox)
    available = SIZE - (SAFE_INSET * 2)
    scale = min(1.0, available / content.width, available / content.height)
    resized = content.resize(
        (round(content.width * scale), round(content.height * scale)),
        Image.Resampling.LANCZOS,
    )
    fitted = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fitted.alpha_composite(resized, ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2))
    fitted_bbox = fitted.getchannel("A").getbbox()
    if fitted_bbox is None or min(fitted_bbox[0], fitted_bbox[1], SIZE - fitted_bbox[2], SIZE - fitted_bbox[3]) < SAFE_INSET:
        raise ValueError(f"Foreground artwork exceeds the {SAFE_INSET}px safe inset: {fitted_bbox}")
    return fitted


def build_background() -> Image.Image:
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    vertical = (y / (SIZE - 1))[..., None]
    top = np.array([231, 248, 255], dtype=np.float32)
    bottom = np.array([72, 193, 241], dtype=np.float32)
    pixels = top * (1 - vertical) + bottom * vertical

    glow = np.exp(-(((x - 505) / 520) ** 2 + ((y - 365) / 410) ** 2))[..., None]
    pixels = pixels * (1 - 0.24 * glow) + np.array([255, 255, 255], dtype=np.float32) * 0.24 * glow
    background = Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8)).convert("RGBA")

    overlay_large = Image.new("RGBA", (SIZE * AA, SIZE * AA), (0, 0, 0, 0))
    overlay = ImageDraw.Draw(overlay_large)

    rear_wave = cubic_points(
        (0, 642),
        [
            (125, 622, 244, 750, 352, 837),
            (466, 929, 596, 923, 724, 831),
            (849, 742, 935, 691, 1024, 685),
            (1024, 685, 1024, 1024, 1024, 1024),
            (1024, 1024, 0, 1024, 0, 1024),
            (0, 1024, 0, 642, 0, 642),
        ],
    )
    overlay.polygon(scaled(rear_wave), fill=(38, 177, 235, 88))

    front_wave = cubic_points(
        (0, 761),
        [
            (142, 773, 274, 894, 422, 922),
            (563, 950, 703, 894, 822, 807),
            (915, 740, 976, 713, 1024, 706),
            (1024, 706, 1024, 1024, 1024, 1024),
            (1024, 1024, 0, 1024, 0, 1024),
            (0, 1024, 0, 761, 0, 761),
        ],
    )
    overlay.polygon(scaled(front_wave), fill=(16, 153, 230, 74))

    # The pale ribbon echoes the original wave without creating a baked icon border.
    ribbon = cubic_points(
        (0, 753),
        [
            (140, 761, 270, 882, 421, 912),
            (559, 939, 696, 885, 816, 799),
            (908, 734, 970, 704, 1024, 697),
        ],
        steps=36,
    )
    overlay.line(scaled(ribbon), fill=(238, 252, 255, 185), width=13 * AA, joint="curve")

    wave_layer = overlay_large.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    background.alpha_composite(wave_layer)
    return background.convert("RGB")


def checkerboard() -> Image.Image:
    board = Image.new("RGB", (SIZE, SIZE), (238, 242, 246))
    draw = ImageDraw.Draw(board)
    cell = 64
    for row in range(0, SIZE, cell):
        for column in range(0, SIZE, cell):
            if (row // cell + column // cell) % 2:
                draw.rectangle((column, row, column + cell - 1, row + cell - 1), fill=(211, 219, 227))
    return board


def main() -> None:
    reference = Image.open(REFERENCE).convert("RGBA")
    if reference.size != (SIZE, SIZE):
        raise ValueError(f"Reference must be {SIZE}x{SIZE}, got {reference.size}")

    foreground = build_foreground(reference)
    background = build_background()
    composite = Image.alpha_composite(background.convert("RGBA"), foreground).convert("RGB")

    for media_dir in (APP_SCOPE_MEDIA, ENTRY_MEDIA):
        media_dir.mkdir(parents=True, exist_ok=True)
        foreground.save(media_dir / "app_icon_foreground.png", optimize=True)
        background.save(media_dir / "app_icon_background.png", optimize=True)
    composite.save(LISTING_ICON, optimize=True)

    preview_foreground = checkerboard().convert("RGBA")
    preview_foreground.alpha_composite(foreground)
    preview = Image.new("RGB", (SIZE * 2, SIZE * 2), "white")
    preview.paste(reference.convert("RGB"), (0, 0))
    preview.paste(preview_foreground.convert("RGB"), (SIZE, 0))
    preview.paste(background, (0, SIZE))
    preview.paste(composite, (SIZE, SIZE))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.resize((SIZE, SIZE), Image.Resampling.LANCZOS).save(PREVIEW, optimize=True)


if __name__ == "__main__":
    main()
