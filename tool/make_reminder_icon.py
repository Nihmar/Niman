"""Rasterize the reminder status-bar icon as white-on-transparent PNGs.

Android masks a notification small icon to its alpha channel and tints
the result, so the glyph is pure white and everything else transparent.
Drawn here rather than shipped as a vector: a VectorDrawable in
res/drawable/ did not reach the resource table on the build machine,
while the density-qualified mipmap PNGs do.

Pure stdlib (zlib only), so it runs anywhere the repo does.
"""

import math
import struct
import zlib

# Glyph geometry in a 24x24 design space (the Material "alarm" shape).
CX = CY = 12.0
RING_OUTER = 9.0
RING_INNER = 7.2
HANDS = [
    # (angle from 12 o'clock in degrees, length, half-width)
    (0.0, 5.0, 0.85),    # minute hand, straight up
    (120.0, 3.7, 0.85),  # hour hand, roughly 4 o'clock
]
BELLS = [
    # (angle, inner radius, outer radius, half-width)
    (-45.0, 8.4, 11.3, 1.15),
    (45.0, 8.4, 11.3, 1.15),
]
SUPERSAMPLE = 4


def _point_at(angle_deg, radius):
    """The point at [radius] from the centre, [angle_deg] from 12 o'clock."""
    rad = math.radians(angle_deg)
    return (CX + radius * math.sin(rad), CY - radius * math.cos(rad))


def _segment_distance(px, py, ax, ay, bx, by):
    """Distance from (px, py) to the segment (ax, ay)-(bx, by)."""
    dx, dy = bx - ax, by - ay
    span = dx * dx + dy * dy
    if span == 0:
        return math.hypot(px - ax, py - ay)
    t = ((px - ax) * dx + (py - ay) * dy) / span
    t = max(0.0, min(1.0, t))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def _covered(x, y):
    """Whether the design-space point (x, y) is inside the glyph."""
    radius = math.hypot(x - CX, y - CY)
    if RING_INNER <= radius <= RING_OUTER:
        return True
    for angle, length, half in HANDS:
        ax, ay = _point_at(angle, length)
        if _segment_distance(x, y, CX, CY, ax, ay) <= half:
            return True
    for angle, inner, outer, half in BELLS:
        ax, ay = _point_at(angle, inner)
        bx, by = _point_at(angle, outer)
        if _segment_distance(x, y, ax, ay, bx, by) <= half:
            return True
    return False


def _alpha_rows(size):
    """Anti-aliased alpha rows, supersampled, in design space."""
    scale = 24.0 / size
    step = scale / SUPERSAMPLE
    offset = step / 2.0
    rows = []
    for py in range(size):
        row = bytearray()
        for px in range(size):
            hits = 0
            for sy in range(SUPERSAMPLE):
                y = py * scale + offset + sy * step
                for sx in range(SUPERSAMPLE):
                    x = px * scale + offset + sx * step
                    if _covered(x, y):
                        hits += 1
            alpha = round(255 * hits / (SUPERSAMPLE * SUPERSAMPLE))
            row += bytes((255, 255, 255, alpha))
        rows.append(bytes(row))
    return rows


def _chunk(tag, data):
    body = tag + data
    return struct.pack('>I', len(data)) + body + struct.pack(
        '>I', zlib.crc32(body) & 0xFFFFFFFF)


def write_png(path, size):
    """Writes the glyph at [size] x [size] as an RGBA PNG."""
    rows = _alpha_rows(size)
    raw = b''.join(b'\x00' + row for row in rows)
    png = b'\x89PNG\r\n\x1a\n'
    png += _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
    png += _chunk(b'IDAT', zlib.compress(raw, 9))
    png += _chunk(b'IEND', b'')
    with open(path, 'wb') as handle:
        handle.write(png)
    return len(png)


if __name__ == '__main__':
    import os
    import sys

    base = sys.argv[1]
    # Notification small icons: 24dp square, one PNG per density bucket.
    for bucket, size in (
        ('mdpi', 24),
        ('hdpi', 36),
        ('xhdpi', 48),
        ('xxhdpi', 72),
        ('xxxhdpi', 96),
    ):
        folder = os.path.join(base, 'drawable-' + bucket)
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, 'ic_stat_reminder.png')
        print(bucket, size, write_png(path, size), 'bytes')
