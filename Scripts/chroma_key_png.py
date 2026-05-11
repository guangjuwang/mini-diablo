#!/usr/bin/env python3.12
from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


PNG_SIG = b"\x89PNG\r\n\x1a\n"


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def read_png(path: Path) -> tuple[int, int, int, list[bytearray]]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIG):
        raise ValueError(f"{path} is a PNG file")

    offset = len(PNG_SIG)
    width = height = color_type = bit_depth = 0
    compressed = bytearray()
    while offset < len(data):
        length = int.from_bytes(data[offset:offset + 4], "big")
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", payload[:10])
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            break

    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(f"{path} uses color type {color_type} and bit depth {bit_depth}")

    channels = 4 if color_type == 6 else 3
    stride = width * channels
    raw = zlib.decompress(bytes(compressed))
    rows: list[bytearray] = []
    previous = bytearray(stride)
    cursor = 0
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        scanline = bytearray(raw[cursor:cursor + stride])
        cursor += stride
        for index, value in enumerate(scanline):
            left = scanline[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 1:
                scanline[index] = (value + left) & 0xFF
            elif filter_type == 2:
                scanline[index] = (value + up) & 0xFF
            elif filter_type == 3:
                scanline[index] = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                scanline[index] = (value + paeth(left, up, upper_left)) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"Unsupported PNG filter {filter_type}")
        rows.append(scanline)
        previous = scanline
    return width, height, channels, rows


def write_rgba_png(path: Path, width: int, height: int, rows: list[bytearray]) -> None:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            len(payload).to_bytes(4, "big")
            + kind
            + payload
            + zlib.crc32(kind + payload).to_bytes(4, "big")
        )

    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(PNG_SIG + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def is_grid_line(x: int, y: int, width: int, height: int, thickness: int) -> bool:
    verticals = [round(width * k / 4) for k in range(1, 4)]
    horizontals = [round(height * k / 4) for k in range(1, 4)]
    return any(abs(x - value) <= thickness for value in verticals) or any(abs(y - value) <= thickness for value in horizontals)


def chroma_key(input_path: Path, output_path: Path, threshold: int, opaque: int, grid_thickness: int) -> None:
    width, height, channels, rows = read_png(input_path)
    key_samples = []
    for x, y in [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]:
        row = rows[y]
        start = x * channels
        key_samples.append(tuple(row[start:start + 3]))
    key = tuple(sum(sample[index] for sample in key_samples) // len(key_samples) for index in range(3))

    out_rows: list[bytearray] = []
    for y, row in enumerate(rows):
        out = bytearray(width * 4)
        for x in range(width):
            start = x * channels
            r, g, b = row[start:start + 3]
            source_alpha = row[start + 3] if channels == 4 else 255
            distance = max(abs(r - key[0]), abs(g - key[1]), abs(b - key[2]))
            neutral = max(r, g, b) - min(r, g, b) <= 10 and sum((r, g, b)) // 3 >= 170
            green_screen = g >= 120 and (g - max(r, b)) >= 45
            if green_screen or distance <= threshold or (neutral and is_grid_line(x, y, width, height, grid_thickness)):
                alpha = 0
            elif distance >= opaque:
                alpha = source_alpha
            else:
                alpha = round(source_alpha * (distance - threshold) / max(1, opaque - threshold))
                if g > r and g > b:
                    g = round((r + b) / 2)
            target = x * 4
            out[target:target + 4] = bytes((r, g, b, max(0, min(255, alpha))))
        out_rows.append(out)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    write_rgba_png(output_path, width, height, out_rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--threshold", type=int, default=28)
    parser.add_argument("--opaque", type=int, default=150)
    parser.add_argument("--grid-thickness", type=int, default=3)
    args = parser.parse_args()
    chroma_key(args.input, args.out, args.threshold, args.opaque, args.grid_thickness)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
