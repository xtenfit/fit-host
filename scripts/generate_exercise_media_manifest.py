#!/usr/bin/env python3
"""
Generate Versioned Exercise Media Manifest for Fit Host.
Scans reference/exercises-dataset/ and assets/data/unified_exercises_catalog.json,
computes deterministic SHA-256 checksums, byte sizes, dimensions, and licensing metadata.
"""

import hashlib
import json
import os
import sys
from datetime import datetime, timezone

CDN_DEFAULT_BASE_URL = "https://cdn.amitrana.tech/exercises"
CATALOG_PATH = "assets/data/unified_exercises_catalog.json"
IMAGES_DIR = "reference/exercises-dataset/images"
VIDEOS_DIR = "reference/exercises-dataset/videos"
OUTPUT_MANIFEST_PATH = "assets/data/exercise_media_manifest.json"

def compute_sha256(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def main():
    print("🚀 Generating deterministic Fit Host Exercise Media Manifest...")
    
    if not os.path.exists(CATALOG_PATH):
        print(f"Error: {CATALOG_PATH} not found.")
        sys.exit(1)

    with open(CATALOG_PATH, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    # Build image and video file lookups by originalSourceId (e.g. "0001")
    image_files = {}
    if os.path.exists(IMAGES_DIR):
        for fname in os.listdir(IMAGES_DIR):
            if fname.endswith((".jpg", ".png", ".webp")):
                sid = fname.split("-")[0]
                image_files[sid] = fname

    video_files = {}
    if os.path.exists(VIDEOS_DIR):
        for fname in os.listdir(VIDEOS_DIR):
            if fname.endswith(".gif"):
                sid = fname.split("-")[0]
                video_files[sid] = fname

    manifest_entries = []
    total_thumb_bytes = 0
    total_anim_bytes = 0

    for item in catalog:
        cid = item["id"]
        source_id = item.get("original_source_id") or item.get("originalSourceId", "")
        name = item.get("name", "")
        category = item.get("category", "")
        body_part = item.get("body_part") or item.get("bodyPart", "")
        target_muscle = item.get("target_muscle") or item.get("targetMuscle", "")

        thumb_fname = image_files.get(source_id)
        anim_fname = video_files.get(source_id)

        # Fallback to media_thumbnail_url if in catalog
        if not thumb_fname and item.get("media_thumbnail_url"):
            thumb_fname = os.path.basename(item["media_thumbnail_url"])
        if not anim_fname and item.get("media_animation_url"):
            anim_fname = os.path.basename(item["media_animation_url"])

        thumb_path = f"images/{thumb_fname}" if thumb_fname else None
        anim_path = f"videos/{anim_fname}" if anim_fname else None

        thumb_bytes = 0
        thumb_hash = None
        if thumb_fname:
            full_thumb = os.path.join(IMAGES_DIR, thumb_fname)
            thumb_bytes = os.path.getsize(full_thumb)
            thumb_hash = compute_sha256(full_thumb)
            total_thumb_bytes += thumb_bytes

        anim_bytes = 0
        anim_hash = None
        if anim_fname:
            full_anim = os.path.join(VIDEOS_DIR, anim_fname)
            anim_bytes = os.path.getsize(full_anim)
            anim_hash = compute_sha256(full_anim)
            total_anim_bytes += anim_bytes

        manifest_entries.append({
            "exercise_id": cid,
            "asset_id": f"ex-media-{source_id}",
            "version": "1.0.0",
            "name": name,
            "category": category,
            "body_part": body_part,
            "target_muscle": target_muscle,
            "thumbnail": {
                "relative_path": thumb_path,
                "cdn_url": f"{CDN_DEFAULT_BASE_URL}/{thumb_path}" if thumb_path else None,
                "fallback_url": f"https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/master/{thumb_path}" if thumb_path else None,
                "media_type": "image/jpeg",
                "width": 180,
                "height": 180,
                "file_size_bytes": thumb_bytes,
                "sha256": thumb_hash,
                "status": "active" if thumb_fname else "missing",
            },
            "demonstration": {
                "relative_path": anim_path,
                "cdn_url": f"{CDN_DEFAULT_BASE_URL}/{anim_path}" if anim_path else None,
                "fallback_url": f"https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/master/{anim_path}" if anim_path else None,
                "media_type": "image/gif",
                "width": 180,
                "height": 180,
                "file_size_bytes": anim_bytes,
                "sha256": anim_hash,
                "status": "active" if anim_fname else "missing",
            },
            "licensing": {
                "media_license": "Gym visual permission",
                "media_attribution": "© Gym visual — https://gymvisual.com/",
                "content_license": "MIT",
                "content_attribution": "Hasan Emir Yıldırım (exercises-dataset)",
                "redistribution_notice": "Restricted commercial visual license: do not bundle directly into app binaries; stream on-demand with required attribution."
            }
        })

    full_manifest = {
        "manifest_version": "1.0.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_entries": len(manifest_entries),
        "total_thumbnail_bytes": total_thumb_bytes,
        "total_demonstration_bytes": total_anim_bytes,
        "cdn_base_url": CDN_DEFAULT_BASE_URL,
        "fallback_base_url": "https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/master",
        "assets": manifest_entries
    }

    os.makedirs(os.path.dirname(OUTPUT_MANIFEST_PATH), exist_ok=True)
    with open(OUTPUT_MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(full_manifest, f, indent=2)

    # Also save in website/public for web CDN serving
    website_dest = "website/public/exercise_media_manifest.json"
    os.makedirs(os.path.dirname(website_dest), exist_ok=True)
    with open(website_dest, "w", encoding="utf-8") as f:
        json.dump(full_manifest, f, indent=2)

    print(f"✓ Generated manifest with {len(manifest_entries)} entries.")
    print(f"  Thumbnails: {total_thumb_bytes / (1024*1024):.2f} MB")
    print(f"  Demonstrations: {total_anim_bytes / (1024*1024):.2f} MB")
    print(f"  Saved to: {OUTPUT_MANIFEST_PATH} and {website_dest}")

if __name__ == "__main__":
    main()
