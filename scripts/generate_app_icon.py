from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024
OUTPUT_DIR = Path("/Users/rich/Projects/Jupiter/tmp/app-icon")


CREAM = (247, 239, 226, 255)
CREAM_SHADOW = (228, 214, 194, 255)
WARM_RED = (225, 88, 73, 255)
WARM_RED_ALT = (214, 104, 87, 255)
COCOA = (145, 78, 71, 255)
COCOA_LIGHT = (172, 102, 95, 255)
GOLD = (214, 174, 103, 255)
PAPER = (255, 251, 245, 255)
PAPER_LINE = (234, 219, 197, 255)
SHADOW = (126, 91, 79, 48)


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        ratio = y / max(size - 1, 1)
        color = tuple(
            int(top[index] * (1 - ratio) + bottom[index] * ratio)
            for index in range(3)
        ) + (255,)
        draw.line((0, y, size, y), fill=color)
    return image


def add_shadow(base: Image.Image, bbox: tuple[int, int, int, int], radius: int = 22, offset: tuple[int, int] = (0, 12)) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    shifted = (
        bbox[0] + offset[0],
        bbox[1] + offset[1],
        bbox[2] + offset[0],
        bbox[3] + offset[1],
    )
    draw.rounded_rectangle(shifted, radius=radius, fill=SHADOW)
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(shadow)


def draw_star(draw: ImageDraw.ImageDraw, center: tuple[int, int], size: int, color: tuple[int, int, int, int]) -> None:
    cx, cy = center
    draw.line((cx - size, cy, cx + size, cy), fill=color, width=4)
    draw.line((cx, cy - size, cx, cy + size), fill=color, width=4)
    draw.line((cx - size * 0.7, cy - size * 0.7, cx + size * 0.7, cy + size * 0.7), fill=color, width=3)
    draw.line((cx - size * 0.7, cy + size * 0.7, cx + size * 0.7, cy - size * 0.7), fill=color, width=3)


def draw_polaroid(
    canvas: Image.Image,
    center: tuple[float, float],
    size: tuple[int, int],
    angle: float,
    photo_variant: str,
    accent: str = "planet",
    back: bool = False,
) -> None:
    width, height = size
    card = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)

    outer_radius = 28
    draw.rounded_rectangle((0, 0, width, height), radius=outer_radius, fill=PAPER, outline=(0, 0, 0, 0))
    draw.rounded_rectangle((0, 0, width - 1, height - 1), radius=outer_radius, outline=PAPER_LINE, width=4)

    frame_margin = 34
    bottom_caption = 90
    inner = (
        frame_margin,
        frame_margin,
        width - frame_margin,
        height - frame_margin - bottom_caption,
    )
    draw.rounded_rectangle(inner, radius=22, fill=(251, 246, 238, 255), outline=(225, 213, 193, 255), width=3)

    px0, py0, px1, py1 = inner
    horizon_y = int(py0 + (py1 - py0) * (0.72 if photo_variant == "low" else 0.64))
    draw.rounded_rectangle((px0, py0, px1, py1), radius=22, fill=(252, 245, 236, 255))
    draw.rectangle((px0, horizon_y, px1, py1), fill=(243, 226, 206, 255))

    if photo_variant == "mountain":
        draw.polygon(
            [
                (px0 + 28, horizon_y),
                (px0 + 112, py0 + 110),
                (px0 + 182, horizon_y),
            ],
            fill=(228, 198, 172, 255),
        )
        draw.polygon(
            [
                (px0 + 132, horizon_y),
                (px0 + 220, py0 + 84),
                (px0 + 318, horizon_y),
            ],
            fill=(215, 182, 153, 255),
        )
    else:
        draw.arc((px0 + 40, py0 + 85, px0 + 270, py0 + 240), start=190, end=338, fill=(219, 186, 156, 255), width=8)
        draw.arc((px0 + 160, py0 + 52, px0 + 342, py0 + 210), start=195, end=345, fill=(235, 205, 176, 255), width=7)

    draw.line((px0 + 34, horizon_y, px1 - 34, horizon_y), fill=(214, 185, 156, 255), width=6)

    if accent == "planet":
        planet_x = px1 - 88
        planet_y = py0 + 78
        draw.ellipse((planet_x - 28, planet_y - 28, planet_x + 28, planet_y + 28), fill=WARM_RED_ALT)
        draw.arc((planet_x - 42, planet_y - 18, planet_x + 42, planet_y + 18), start=195, end=345, fill=COCOA_LIGHT, width=4)
    else:
        draw.ellipse((px1 - 108, py0 + 58, px1 - 68, py0 + 98), fill=GOLD)
        draw_star(draw, (px1 - 62, py0 + 72), 10, GOLD)

    if back:
        overlay = Image.new("RGBA", (width, height), (255, 255, 255, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        overlay_draw.rounded_rectangle((0, 0, width, height), radius=outer_radius, fill=(255, 255, 255, 20))
        card = Image.alpha_composite(card, overlay)

    rotated = card.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    x = int(center[0] - rotated.size[0] / 2)
    y = int(center[1] - rotated.size[1] / 2)
    canvas.alpha_composite(rotated, (x, y))


def build_icon(circle_color: tuple[int, int, int, int], back_angle: float, front_angle: float, accent: str, photo_variant: str, suffix: str) -> Path:
    base = vertical_gradient(SIZE, CREAM[:3], CREAM_SHADOW[:3])
    icon = base.copy()

    draw = ImageDraw.Draw(icon)

    circle_bbox = (214, 212, 810, 808)
    add_shadow(icon, circle_bbox, radius=300, offset=(0, 18))
    draw.ellipse(circle_bbox, fill=circle_color)

    back_center = (470, 468)
    front_center = (548, 556)
    card_size = (354, 424)

    add_shadow(icon, (270, 250, 650, 690), radius=40, offset=(-12, 20))
    draw_polaroid(icon, back_center, card_size, angle=back_angle, photo_variant=photo_variant, accent="star", back=True)

    add_shadow(icon, (378, 318, 778, 786), radius=40, offset=(0, 22))
    draw_polaroid(icon, front_center, card_size, angle=front_angle, photo_variant=photo_variant, accent=accent, back=False)

    draw_star(draw, (756, 300), 18, GOLD)
    draw_star(draw, (790, 330), 9, GOLD)

    output_path = OUTPUT_DIR / f"app-icon-polaroid-{suffix}.png"
    icon.save(output_path)
    return output_path


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    outputs: Iterable[Path] = [
        build_icon(WARM_RED, back_angle=-10, front_angle=3, accent="planet", photo_variant="mountain", suffix="v1"),
        build_icon(WARM_RED_ALT, back_angle=-14, front_angle=7, accent="star", photo_variant="mountain", suffix="v2"),
        build_icon(WARM_RED, back_angle=-8, front_angle=-2, accent="planet", photo_variant="low", suffix="v3"),
    ]

    for path in outputs:
        print(path)


if __name__ == "__main__":
    main()
