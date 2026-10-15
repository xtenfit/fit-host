import subprocess, os

# Let's test with a simple script
print("Testing sips cropOffset...")
# Source is Neon Running and Cycling Duo.png (1670 x 941)
# We want Runner (left half) and Cyclist (right half)
# Total width: 1670. Total height: 941.
# Runner is roughly x: 0 to 860.
# Cyclist is roughly x: 800 to 1670.

# In sips:
# What does --cropOffset Y X do?
# If we do --cropOffset 0 0, does it crop from (0,0) or does it mean something else?
for offset_x in [0, 200, 400, 600, 800]:
    out = f"build/crop_x_{offset_x}.png"
    subprocess.run(["sips", "-c", "941", "600", "--cropOffset", "0", str(offset_x), "assets/Neon Running and Cycling Duo.png", "-o", out], capture_output=True)
    print(f"Created {out}")
