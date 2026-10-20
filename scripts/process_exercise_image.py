#!/usr/bin/env python3
"""
Fit Host — Exercise Image Transparency Processor
Converts pure-white background exercise illustrations into genuine alpha-channel transparent PNGs.
Uses flood-fill from border edges combined with high-luminance background removal and alpha anti-aliasing.
"""

import sys
import os
import cv2
import numpy as np
from PIL import Image

def convert_to_transparent_png(src_path: str, dst_path: str):
    if not os.path.exists(src_path):
        raise FileNotFoundError(f"Source file not found: {src_path}")
    
    os.makedirs(os.path.dirname(os.path.abspath(dst_path)), exist_ok=True)
    
    img = Image.open(src_path).convert("RGBA")
    arr = np.array(img)
    h, w = arr.shape[:2]

    # Convert to BGR for OpenCV floodFill
    bgr = cv2.cvtColor(arr[:, :, :3], cv2.COLOR_RGB2BGR)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    diff = (18, 18, 18)

    # Perimeter sample points for floodFill
    perimeter_points = [
        (0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
        (w // 2, 0), (0, h // 2), (w - 1, h // 2), (w // 2, h - 1),
        (w // 4, 0), (3 * w // 4, 0), (0, h // 4), (0, 3 * h // 4),
        (w - 1, h // 4), (w - 1, 3 * h // 4), (w // 4, h - 1), (3 * w // 4, h - 1)
    ]

    for pt in perimeter_points:
        # Only floodfill if the point itself is light
        val = bgr[pt[1], pt[0]]
        if int(val[0]) + int(val[1]) + int(val[2]) > 600:
            cv2.floodFill(bgr, mask, pt, (0, 0, 0), diff, diff, flags=cv2.FLOODFILL_MASK_ONLY | (255 << 8))

    # Identify background pixels
    bg_mask = (mask[1:-1, 1:-1] == 255) | (np.all(arr[:, :, :3] >= 246, axis=-1))

    # Strip background to 0 alpha
    arr[bg_mask, 3] = 0

    # Gentle anti-aliasing on alpha border
    alpha = arr[:, :, 3].astype(np.float32)
    alpha_blurred = cv2.GaussianBlur(alpha, (3, 3), 0)
    arr[:, :, 3] = np.where(bg_mask, 0, alpha_blurred.astype(np.uint8))

    # Save PNG
    res = Image.fromarray(arr)
    res.save(dst_path, "PNG")
    print(f"Processed: {src_path} -> {dst_path} ({res.size[0]}x{res.size[1]})")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 process_exercise_image.py <src_image> <dst_png>")
        sys.exit(1)
    convert_to_transparent_png(sys.argv[1], sys.argv[2])
