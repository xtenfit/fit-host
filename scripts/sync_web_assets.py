import os
import shutil
import glob
import json
import base64
import struct

def encode_size(n):
    if n < 254:
        return bytes([n])
    elif n <= 0xFFFF:
        return bytes([254]) + struct.pack('>H', n)
    else:
        return bytes([255]) + struct.pack('>I', n)

def encode_codec(obj):
    if obj is None:
        return bytes([0])
    elif obj is True:
        return bytes([1])
    elif obj is False:
        return bytes([2])
    elif isinstance(obj, int):
        return bytes([3]) + struct.pack('>i', obj)
    elif isinstance(obj, str):
        b = obj.encode('utf-8')
        return bytes([7]) + encode_size(len(b)) + b
    elif isinstance(obj, list):
        out = bytes([12]) + encode_size(len(obj))
        for item in obj:
            out += encode_codec(item)
        return out
    elif isinstance(obj, dict):
        out = bytes([13]) + encode_size(len(obj))
        for k, v in obj.items():
            out += encode_codec(k) + encode_codec(v)
        return out
    else:
        raise ValueError(f"Cannot encode {type(obj)}")

def main():
    print("Collecting all assets from assets/ ...")
    all_files = []
    for root, dirs, files in os.walk("assets"):
        for f in files:
            if not f.startswith("."):
                rel_path = os.path.join(root, f)
                all_files.append(rel_path)
    
    print(f"Found {len(all_files)} assets.")
    
    # Build manifest map
    manifest_map = {}
    legacy_json_map = {}
    for f in all_files:
        manifest_map[f] = [{"asset": f}]
        legacy_json_map[f] = [f]
        
    # Also add cupertino icons font if present
    cupertino_font = "packages/cupertino_icons/assets/CupertinoIcons.ttf"
    manifest_map[cupertino_font] = [{"asset": cupertino_font}]
    legacy_json_map[cupertino_font] = [cupertino_font]
    
    # Encode binary manifest
    bin_bytes = encode_codec(manifest_map)
    b64_str = base64.b64encode(bin_bytes).decode("ascii")
    b64_json = json.dumps(b64_str)
    legacy_json = json.dumps(legacy_json_map, indent=2)
    
    dest_dirs = [
        "build/web/assets",
        "build/flutter_assets"
    ]
    
    for d in dest_dirs:
        if not os.path.exists(d):
            continue
        print(f"Syncing assets to {d} ...")
        
        # Copy assets directory tree into dest
        target_assets = os.path.join(d, "assets")
        if os.path.exists(target_assets):
            shutil.rmtree(target_assets)
        shutil.copytree("assets", target_assets)
        
        # Write AssetManifest.bin
        with open(os.path.join(d, "AssetManifest.bin"), "wb") as f:
            f.write(bin_bytes)
            
        # Write AssetManifest.bin.json
        with open(os.path.join(d, "AssetManifest.bin.json"), "w") as f:
            f.write(b64_json)
            
        # Write AssetManifest.json
        with open(os.path.join(d, "AssetManifest.json"), "w") as f:
            f.write(legacy_json)
            
    print("Assets successfully synced to web and flutter runner builds!")

if __name__ == "__main__":
    main()
