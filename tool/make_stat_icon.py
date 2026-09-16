"""Rasterize the app mark as the notification status-bar icon.

Android masks a notification small icon to its alpha channel and tints
the result, so the mark ships as white-on-transparent and its colours
(the blue of the "i") cannot survive. What reaches the status bar is the
silhouette of the launcher foreground's ink.

Derived from `mipmap-xxxhdpi/ic_launcher_foreground.png` rather than
redrawn, so the mark cannot drift from the launcher icon. The adaptive
icon keeps its glyph inside a small safe zone; here it is cropped to its
ink and scaled to fill the 24dp canvas the status bar draws in.

Density PNGs rather than a vector, for the reason `todo_reminder.dart`
records: a VectorDrawable under `res/drawable/` did not reach the
resource table on the build machine, while these buckets do.

Pure stdlib (zlib only), so it runs anywhere the repo does.
"""

import os
import struct
import sys
import zlib

# Material asks for a 24dp canvas with the glyph inside 22dp: a hair of
# padding keeps the mark off the status bar's edge.
INSET = 22.0 / 24.0
BUCKETS = (('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72),
           ('xxxhdpi', 96))


def _chunks(data):
    """Yields (tag, payload) for each chunk of the PNG in [data]."""
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('not a PNG')
    at = 8
    while at < len(data):
        (length,) = struct.unpack('>I', data[at:at + 4])
        tag = data[at + 4:at + 8]
        yield tag, data[at + 8:at + 8 + length]
        at += 12 + length


def read_alpha(path):
    """The alpha channel of an 8-bit RGBA PNG, as (width, height, rows)."""
    blob = open(path, 'rb').read()
    width = height = None
    body = b''
    for tag, payload in _chunks(blob):
        if tag == b'IHDR':
            width, height, depth, colour = struct.unpack('>IIBB', payload[:10])
            if (depth, colour) != (8, 6):
                raise ValueError('want 8-bit RGBA, got depth %d type %d'
                                 % (depth, colour))
        elif tag == b'IDAT':
            body += payload
    raw = zlib.decompress(body)
    stride = width * 4
    rows = []
    previous = bytearray(stride)
    at = 0
    for _ in range(height):
        method = raw[at]
        line = bytearray(raw[at + 1:at + 1 + stride])
        at += 1 + stride
        for i in range(stride):
            left = line[i - 4] if i >= 4 else 0
            up = previous[i]
            upleft = previous[i - 4] if i >= 4 else 0
            if method == 1:
                line[i] = (line[i] + left) & 0xFF
            elif method == 2:
                line[i] = (line[i] + up) & 0xFF
            elif method == 3:
                line[i] = (line[i] + (left + up) // 2) & 0xFF
            elif method == 4:
                p = left + up - upleft
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - upleft)
                best = left if (pa <= pb and pa <= pc) else (
                    up if pb <= pc else upleft)
                line[i] = (line[i] + best) & 0xFF
            elif method != 0:
                raise ValueError('unknown filter %d' % method)
        rows.append(bytes(line[3::4]))
        previous = line
    return width, height, rows


def ink_box(width, height, rows, threshold=8):
    """The bounding box of the opaque pixels, as (left, top, right, bottom)."""
    left, top, right, bottom = width, height, -1, -1
    for y in range(height):
        row = rows[y]
        for x in range(width):
            if row[x] >= threshold:
                left = min(left, x)
                right = max(right, x)
                top = min(top, y)
                bottom = max(bottom, y)
    if right < 0:
        raise ValueError('the source has no opaque pixels')
    return left, top, right + 1, bottom + 1


def scaled(rows, box, out_w, out_h):
    """Area-averaged downscale of the boxed region to out_w x out_h."""
    left, top, right, bottom = box
    src_w, src_h = right - left, bottom - top
    out = []
    for y in range(out_h):
        y0 = top + y * src_h / out_h
        y1 = top + (y + 1) * src_h / out_h
        row = bytearray()
        for x in range(out_w):
            x0 = left + x * src_w / out_w
            x1 = left + (x + 1) * src_w / out_w
            total = weight = 0.0
            for sy in range(int(y0), min(int(y1) + 1, bottom)):
                cover_y = min(y1, sy + 1) - max(y0, sy)
                if cover_y <= 0:
                    continue
                source = rows[sy]
                for sx in range(int(x0), min(int(x1) + 1, right)):
                    cover_x = min(x1, sx + 1) - max(x0, sx)
                    if cover_x <= 0:
                        continue
                    area = cover_x * cover_y
                    total += source[sx] * area
                    weight += area
            row.append(round(total / weight) if weight else 0)
        out.append(bytes(row))
    return out


def _chunk(tag, data):
    body = tag + data
    return (struct.pack('>I', len(data)) + body
            + struct.pack('>I', zlib.crc32(body) & 0xFFFFFFFF))


def write_png(path, size, mask, at_x, at_y):
    """Writes [mask] as white-on-transparent, placed on a [size] canvas."""
    raw = b''
    for y in range(size):
        row = bytearray()
        for x in range(size):
            inside = (at_y <= y < at_y + len(mask)
                      and at_x <= x < at_x + len(mask[0]))
            alpha = mask[y - at_y][x - at_x] if inside else 0
            row += bytes((255, 255, 255, alpha))
        raw += b'\x00' + bytes(row)
    png = b'\x89PNG\r\n\x1a\n'
    png += _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
    png += _chunk(b'IDAT', zlib.compress(raw, 9))
    png += _chunk(b'IEND', b'')
    with open(path, 'wb') as handle:
        handle.write(png)
    return len(png)


if __name__ == '__main__':
    res = sys.argv[1]
    source = os.path.join(res, 'mipmap-xxxhdpi', 'ic_launcher_foreground.png')
    width, height, rows = read_alpha(source)
    box = ink_box(width, height, rows)
    glyph_w, glyph_h = box[2] - box[0], box[3] - box[1]
    print('ink %dx%d of %dx%d' % (glyph_w, glyph_h, width, height))
    for bucket, size in BUCKETS:
        inner = round(size * INSET)
        scale = min(inner / glyph_w, inner / glyph_h)
        out_w = max(1, round(glyph_w * scale))
        out_h = max(1, round(glyph_h * scale))
        mask = scaled(rows, box, out_w, out_h)
        folder = os.path.join(res, 'drawable-' + bucket)
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, 'ic_stat_niman.png')
        written = write_png(path, size, mask, (size - out_w) // 2,
                            (size - out_h) // 2)
        print('%-8s %2dpx  glyph %dx%d  %d bytes'
              % (bucket, size, out_w, out_h, written))
