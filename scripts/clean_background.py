import os
from PIL import Image
import numpy as np
import scipy.ndimage as ndimage

def clean_subject_background(src_path, dst_path, brightness_thresh=215, sat_thresh=28, include_bottom=False):
    if not os.path.exists(src_path):
        print(f"File not found: {src_path}")
        return
    
    img = Image.open(src_path).convert('RGB')
    arr = np.array(img, dtype=np.float32)
    h, w, _ = arr.shape
    
    r = arr[:, :, 0]
    g = arr[:, :, 1]
    b = arr[:, :, 2]
    
    brightness = (r + g + b) / 3.0
    saturation = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    
    # Background candidates: light and low color saturation
    is_bg_candidate = (brightness > brightness_thresh) & (saturation < sat_thresh)
    
    # Connected to outer edges
    labeled, num_features = ndimage.label(is_bg_candidate)
    border_mask = np.zeros((h, w), dtype=bool)
    border_mask[0:3, :] = True          # Top border
    border_mask[:, 0:3] = True          # Left border
    border_mask[:, -3:] = True         # Right border
    if include_bottom:
        border_mask[-3:, :] = True     # Bottom border
    
    border_labels = np.unique(labeled[border_mask])
    border_labels = border_labels[border_labels != 0]
    
    bg_mask = np.isin(labeled, border_labels)
    subject_mask = ~bg_mask
    
    # Fill internal holes (eyes, teeth, socks, logos)
    subject_mask = ndimage.binary_fill_holes(subject_mask)
    
    # Keep only subject components with meaningful area (> 2000 pixels)
    sub_labeled, num_sub = ndimage.label(subject_mask)
    if num_sub > 0:
        sizes = ndimage.sum(subject_mask, sub_labeled, range(1, num_sub + 1))
        max_size = np.max(sizes)
        valid = np.where(sizes >= max_size * 0.02)[0] + 1
        subject_mask = np.isin(sub_labeled, valid)
        subject_mask = ndimage.binary_fill_holes(subject_mask)
    
    # Edge feathering
    alpha = subject_mask.astype(np.float32) * 255.0
    alpha = ndimage.gaussian_filter(alpha, sigma=1.2)
    alpha = np.clip(alpha, 0, 255).astype(np.uint8)
    
    out_arr = np.zeros((h, w, 4), dtype=np.uint8)
    out_arr[:, :, 0:3] = np.uint8(arr)
    out_arr[:, :, 3] = alpha
    
    out_img = Image.fromarray(out_arr)
    out_img.save(dst_path, 'PNG')
    print(f"Saved pristine transparent: {dst_path} (pixels: {np.sum(alpha > 0)})")

files = [
    ("assets/images/setup/setup_male_model.jpg", "assets/images/setup/setup_male_model.png", False),
    ("assets/images/setup/setup_female_model.jpg", "assets/images/setup/setup_female_model.png", False),
    ("assets/images/setup/setup_goal_weight.jpg", "assets/images/setup/setup_goal_weight.png", False),
    ("assets/images/setup/setup_goal_muscle.jpg", "assets/images/setup/setup_goal_muscle.png", False),
    ("assets/images/setup/setup_goal_fitness.jpg", "assets/images/setup/setup_goal_fitness.png", False),
    ("assets/images/setup/setup_trainer_shred.jpg", "assets/images/setup/setup_trainer_shred.png", False),
    ("assets/images/setup/setup_coach_avatar.jpg", "assets/images/setup/setup_coach_avatar.png", True),
    ("assets/images/nutrition/hydration.jpg", "assets/images/nutrition/hydration.png", True),
]

for src, dst, inc_bottom in files:
    clean_subject_background(src, dst, include_bottom=inc_bottom)
