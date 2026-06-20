#!/usr/bin/env python3
"""Generate simple launcher icons for the app."""
import struct
import zlib

def create_png(width, height, r, g, b):
    """Create a minimal PNG file with a solid color."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter byte
        for x in range(width):
            # Create a gradient effect
            factor = (x + y) / (width + height)
            rr = int(r * (1 - factor * 0.3))
            gg = int(g * (1 - factor * 0.3))
            bb = int(b * (1 - factor * 0.3))
            raw += bytes([rr, gg, bb])

    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')

    return header + ihdr + idat + iend

# Create icons for different densities
sizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

# Blue gradient icon (water drop theme)
r, g, b = 26, 115, 232  # Water blue

import os
base = '/root/water-tracker/android/app/src/main/res'

for density, size in sizes.items():
    path = f'{base}/mipmap-{density}'
    os.makedirs(path, exist_ok=True)

    # ic_launcher.png
    png = create_png(size, size, r, g, b)
    with open(f'{path}/ic_launcher.png', 'wb') as f:
        f.write(png)

    # ic_launcher_round.png (same for simplicity)
    with open(f'{path}/ic_launcher_round.png', 'wb') as f:
        f.write(png)

print("Icons generated successfully!")
