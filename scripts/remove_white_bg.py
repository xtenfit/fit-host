import sys, os
from PIL import Image

def remove_white_bg(src_path, dst_path, tolerance=240):
    img = Image.open(src_path).convert("RGBA")
    datas = img.getdata()
    newData = []
    for item in datas:
        # If pixel is near pure white
        if item[0] >= tolerance and item[1] >= tolerance and item[2] >= tolerance:
            # smooth alpha transition near edges
            avg = (item[0] + item[1] + item[2]) / 3.0
            if avg >= 250:
                newData.append((255, 255, 255, 0))
            else:
                alpha = int(255 * (255 - avg) / (255 - tolerance))
                newData.append((item[0], item[1], item[2], max(0, min(255, alpha))))
        else:
            newData.append(item)
    img.putdata(newData)
    img.save(dst_path, "PNG")
    print(f"Saved transparent {dst_path}")

files = [
    ("assets/images/setup/setup_male_model.jpg", "assets/images/setup/setup_male_model.png"),
    ("assets/images/setup/setup_female_model.jpg", "assets/images/setup/setup_female_model.png"),
    ("assets/images/setup/setup_goal_weight.jpg", "assets/images/setup/setup_goal_weight.png"),
    ("assets/images/setup/setup_goal_muscle.jpg", "assets/images/setup/setup_goal_muscle.png"),
    ("assets/images/setup/setup_goal_fitness.jpg", "assets/images/setup/setup_goal_fitness.png"),
    ("assets/images/setup/setup_trainer_shred.jpg", "assets/images/setup/setup_trainer_shred.png"),
    ("assets/images/setup/setup_coach_avatar.jpg", "assets/images/setup/setup_coach_avatar.png"),
    ("assets/images/nutrition/hydration.jpg", "assets/images/nutrition/hydration.png"),
]

for src, dst in files:
    if os.path.exists(src):
        remove_white_bg(src, dst)
