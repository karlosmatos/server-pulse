#!/usr/bin/env python3
"""Generate a 1024x1024 macOS app icon for ServerPulse."""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

SIZE = 1024
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Resources")
OUTPUT_PNG = os.path.join(OUTPUT_DIR, "AppIcon.png")


def rounded_rect_mask(size, radius):
    """Create a mask for a rounded rectangle (macOS icon shape)."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def draw_background_gradient(img):
    """Draw a dark gradient background."""
    draw = ImageDraw.Draw(img)
    # Dark navy to slightly lighter gradient (top to bottom)
    top_color = (18, 18, 40)       # Deep dark navy
    bottom_color = (28, 32, 60)    # Slightly lighter navy

    for y in range(SIZE):
        t = y / SIZE
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * t)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * t)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * t)
        draw.line([(0, y), (SIZE - 1, y)], fill=(r, g, b))


def draw_subtle_grid(draw):
    """Draw a subtle circuit/grid pattern in the background."""
    grid_color = (35, 40, 70, 40)  # Very subtle
    spacing = 48

    for x in range(0, SIZE, spacing):
        draw.line([(x, 0), (x, SIZE)], fill=grid_color, width=1)
    for y in range(0, SIZE, spacing):
        draw.line([(0, y), (SIZE, y)], fill=grid_color, width=1)


def draw_circuit_dots(draw):
    """Draw subtle circuit node dots at some grid intersections."""
    dot_color = (40, 55, 90, 70)
    spacing = 48

    import random
    random.seed(42)  # Deterministic
    for x in range(spacing, SIZE, spacing):
        for y in range(spacing, SIZE, spacing):
            if random.random() < 0.08:
                r = 3
                draw.ellipse([x - r, y - r, x + r, y + r], fill=dot_color)


def draw_server_rack_silhouette(draw):
    """Draw a subtle, stylized server rack silhouette behind the pulse line."""
    rack_color = (35, 40, 68, 55)
    led_color = (0, 255, 136, 30)

    # Server rack outline - centered, slightly below center
    rack_x = 280
    rack_y = 300
    rack_w = 464
    rack_h = 500
    corner_r = 20

    draw.rounded_rectangle(
        [rack_x, rack_y, rack_x + rack_w, rack_y + rack_h],
        radius=corner_r,
        outline=rack_color,
        width=3
    )

    # Server unit slots (horizontal lines)
    unit_height = 80
    for i in range(1, 6):
        y = rack_y + i * unit_height
        if y < rack_y + rack_h - 10:
            draw.line([(rack_x + 15, y), (rack_x + rack_w - 15, y)], fill=rack_color, width=2)

    # Small LED dots on each server unit
    for i in range(6):
        y = rack_y + 40 + i * unit_height
        if y < rack_y + rack_h - 30:
            # LED indicator
            draw.ellipse([rack_x + 30, y - 4, rack_x + 38, y + 4], fill=led_color)
            # Drive bay lines
            for j in range(3):
                bx = rack_x + rack_w - 60 + j * 15
                draw.rectangle([bx, y - 6, bx + 8, y + 6], outline=rack_color)


def generate_pulse_points(center_y, amplitude, width_start, width_end):
    """Generate the heartbeat/pulse waveform points."""
    points = []
    num_points = 200

    for i in range(num_points):
        t = i / (num_points - 1)
        x = width_start + (width_end - width_start) * t

        # Create a heartbeat-like waveform
        # Flat -> small dip -> big spike up -> big spike down -> small bump -> flat
        phase = t * 2 * math.pi * 2  # Two full beats across the icon

        # ECG-like waveform using piecewise function
        beat_pos = (t * 2) % 1.0  # Position within each beat (0 to 1)

        if beat_pos < 0.30:
            # Flat baseline with very slight noise
            y_offset = math.sin(beat_pos * 20) * 3
        elif beat_pos < 0.35:
            # P-wave (small bump up)
            local_t = (beat_pos - 0.30) / 0.05
            y_offset = -amplitude * 0.12 * math.sin(local_t * math.pi)
        elif beat_pos < 0.40:
            # Back to baseline
            y_offset = 0
        elif beat_pos < 0.43:
            # Q dip (small dip down)
            local_t = (beat_pos - 0.40) / 0.03
            y_offset = amplitude * 0.10 * math.sin(local_t * math.pi)
        elif beat_pos < 0.50:
            # R peak (big spike UP - the main heartbeat spike)
            local_t = (beat_pos - 0.43) / 0.07
            y_offset = -amplitude * math.sin(local_t * math.pi)
        elif beat_pos < 0.55:
            # S dip (moderate dip down)
            local_t = (beat_pos - 0.50) / 0.05
            y_offset = amplitude * 0.3 * math.sin(local_t * math.pi)
        elif beat_pos < 0.65:
            # Return to baseline
            local_t = (beat_pos - 0.55) / 0.10
            y_offset = amplitude * 0.3 * (1 - local_t) * math.sin(local_t * math.pi * 0.5)
        elif beat_pos < 0.75:
            # T-wave (gentle bump)
            local_t = (beat_pos - 0.65) / 0.10
            y_offset = -amplitude * 0.15 * math.sin(local_t * math.pi)
        else:
            # Flat baseline
            y_offset = math.sin(beat_pos * 15) * 2

        points.append((x, center_y + y_offset))

    return points


def draw_glow_line(img, points, color, width, glow_radius=15):
    """Draw a line with a glow effect."""
    # Create glow layer
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)

    # Draw thick semi-transparent line for glow
    glow_color = (*color[:3], 50)
    for w in range(glow_radius, 0, -2):
        alpha = int(50 * (1 - w / glow_radius))
        c = (*color[:3], alpha)
        for i in range(len(points) - 1):
            glow_draw.line([points[i], points[i + 1]], fill=c, width=w)

    # Blur for smooth glow
    glow = glow.filter(ImageFilter.GaussianBlur(radius=glow_radius))
    img.paste(Image.alpha_composite(img, glow))

    # Draw the main crisp line on top
    main_draw = ImageDraw.Draw(img)
    for i in range(len(points) - 1):
        main_draw.line([points[i], points[i + 1]], fill=color, width=width)


def draw_pulse_endpoint_dot(draw, point, color, radius=12):
    """Draw a glowing dot at the end of the pulse line."""
    x, y = point
    # Outer glow
    for r in range(radius + 10, radius, -1):
        alpha = int(80 * (1 - (r - radius) / 10))
        c = (*color[:3], alpha)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=c)
    # Solid center
    draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)
    # Bright core
    core_r = radius // 2
    bright = (min(255, color[0] + 80), min(255, color[1] + 80), min(255, color[2] + 80), 255)
    draw.ellipse([x - core_r, y - core_r, x + core_r, y + core_r], fill=bright)


def draw_status_indicators(draw):
    """Draw small status indicator dots in the bottom area."""
    indicators = [
        (340, 860, (0, 255, 136, 200)),   # Green - healthy
        (420, 860, (0, 255, 136, 200)),   # Green - healthy
        (500, 860, (0, 255, 136, 200)),   # Green - healthy
        (580, 860, (255, 200, 50, 160)),  # Yellow/amber - warning
        (660, 860, (0, 255, 136, 200)),   # Green - healthy
    ]

    for x, y, color in indicators:
        r = 8
        # Glow
        for gr in range(r + 8, r, -1):
            alpha = int(color[3] * 0.3 * (1 - (gr - r) / 8))
            c = (*color[:3], int(alpha))
            draw.ellipse([x - gr, y - gr, x + gr, y + gr], fill=c)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Create base image with gradient background
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))
    draw_background_gradient(bg)

    # Add subtle grid pattern
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    draw_subtle_grid(overlay_draw)
    draw_circuit_dots(overlay_draw)
    bg = Image.alpha_composite(bg, overlay)

    # Add server rack silhouette
    rack_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rack_draw = ImageDraw.Draw(rack_layer)
    draw_server_rack_silhouette(rack_draw)
    bg = Image.alpha_composite(bg, rack_layer)

    # Generate and draw the pulse/heartbeat line
    pulse_color = (0, 255, 136, 255)  # Bright green
    center_y = SIZE // 2 + 20
    amplitude = 180
    margin = 80

    points = generate_pulse_points(center_y, amplitude, margin, SIZE - margin)
    draw_glow_line(bg, points, pulse_color, width=6, glow_radius=20)

    # Add glowing endpoint dot at the right end of the pulse
    endpoint_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    endpoint_draw = ImageDraw.Draw(endpoint_layer)
    draw_pulse_endpoint_dot(endpoint_draw, points[-1], pulse_color, radius=10)
    bg = Image.alpha_composite(bg, endpoint_layer)

    # Add status indicator dots at bottom
    status_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    status_draw = ImageDraw.Draw(status_layer)
    draw_status_indicators(status_draw)
    bg = Image.alpha_composite(bg, status_layer)

    # Add a subtle vignette effect (darker edges)
    vignette = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    vig_draw = ImageDraw.Draw(vignette)
    center = SIZE // 2
    max_dist = math.sqrt(2) * center
    for ring in range(0, SIZE // 2, 2):
        dist_ratio = ring / (SIZE // 2)
        alpha = int(120 * (dist_ratio ** 2))
        alpha = min(alpha, 180)
        vig_draw.ellipse(
            [center - (SIZE // 2 - ring), center - (SIZE // 2 - ring),
             center + (SIZE // 2 - ring), center + (SIZE // 2 - ring)],
            outline=(0, 0, 0, alpha), width=3
        )
    bg = Image.alpha_composite(bg, vignette)

    # Apply macOS rounded-rect mask
    # macOS icons use ~22.37% corner radius (228.6 / 1024)
    corner_radius = int(SIZE * 0.2237)
    mask = rounded_rect_mask(SIZE, corner_radius)

    # Create final image with transparency
    final = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    final.paste(bg, (0, 0), mask)

    # Add a very subtle 1px inner border for definition
    border_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border_layer)
    border_draw.rounded_rectangle(
        [1, 1, SIZE - 2, SIZE - 2],
        radius=corner_radius,
        outline=(255, 255, 255, 20),
        width=2
    )
    # Mask the border too
    border_masked = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    border_masked.paste(border_layer, (0, 0), mask)
    final = Image.alpha_composite(final, border_masked)

    final.save(OUTPUT_PNG, "PNG")
    print(f"Icon saved to {OUTPUT_PNG}")
    print(f"Size: {final.size}")


if __name__ == "__main__":
    main()
