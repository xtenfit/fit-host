import os
import shutil
import glob
from crop_utils import crop_exact, get_image_size

ASSETS_DIR = "assets"
IMAGES_DIR = os.path.join(ASSETS_DIR, "images")

def clean_target_directories():
    target_subdirs = [
        "anatomy",
        "categories",
        "exercises",
        "nutrition",
        "onboarding",
        "workouts"
    ]
    for sub in target_subdirs:
        path = os.path.join(IMAGES_DIR, sub)
        if os.path.exists(path):
            print(f"Cleaning existing directory: {path}")
            shutil.rmtree(path)
        os.makedirs(path, exist_ok=True)
    print("Cleaned target directories successfully.")

def copy_or_crop(src, dst_png, dst_jpg=None, box=None):
    """
    If box is None, copies the full image (or converts to jpg if needed).
    If box is (x, y, w, h), crops with CoreGraphics.
    """
    if box is None:
        w, h = get_image_size(src)
        box = (0, 0, w, h)
    
    x, y, w, h = box
    crop_exact(src, dst_png, x, y, w, h)
    if dst_jpg:
        crop_exact(src, dst_jpg, x, y, w, h)

def run():
    clean_target_directories()
    
    # ----------------------------------------------------
    # 1. CATEGORIES
    # ----------------------------------------------------
    print("\n--- Processing Categories ---")
    # Neon Fitness Strength and Cardio Duo (1672 x 941)
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon Fitness Strength and Cardio Duo.png"),
        os.path.join(IMAGES_DIR, "categories/strength.png"),
        os.path.join(IMAGES_DIR, "categories/strength.jpg"),
        box=(0, 0, 836, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon Fitness Strength and Cardio Duo.png"),
        os.path.join(IMAGES_DIR, "categories/cardio.png"),
        os.path.join(IMAGES_DIR, "categories/cardio.jpg"),
        box=(836, 0, 836, 941)
    )
    
    # HIIT & Yoga Fitness Cutouts (1671 x 941)
    copy_or_crop(
        os.path.join(ASSETS_DIR, "HIIT & Yoga Fitness Cutouts.png"),
        os.path.join(IMAGES_DIR, "categories/hiit.png"),
        os.path.join(IMAGES_DIR, "categories/hiit.jpg"),
        box=(0, 0, 835, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "HIIT & Yoga Fitness Cutouts.png"),
        os.path.join(IMAGES_DIR, "categories/yoga.png"),
        os.path.join(IMAGES_DIR, "categories/yoga.jpg"),
        box=(835, 0, 836, 941)
    )
    
    # Bodyweight and Mobility Fitness Badges (1671 x 941)
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Bodyweight and Mobility Fitness Badges.png"),
        os.path.join(IMAGES_DIR, "categories/bodyweight.png"),
        os.path.join(IMAGES_DIR, "categories/bodyweight.jpg"),
        box=(0, 0, 812, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Bodyweight and Mobility Fitness Badges.png"),
        os.path.join(IMAGES_DIR, "categories/mobility.png"),
        os.path.join(IMAGES_DIR, "categories/mobility.jpg"),
        box=(812, 0, 859, 941)
    )
    
    # Neon Running and Cycling Duo (1670 x 941)
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon Running and Cycling Duo.png"),
        os.path.join(IMAGES_DIR, "categories/running.png"),
        os.path.join(IMAGES_DIR, "categories/running.jpg"),
        box=(0, 0, 840, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon Running and Cycling Duo.png"),
        os.path.join(IMAGES_DIR, "categories/cycling.png"),
        os.path.join(IMAGES_DIR, "categories/cycling.jpg"),
        box=(845, 0, 825, 941)
    )
    
    # Stretching and Meditation Fitness Duo (1670 x 941)
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Stretching and Meditation Fitness Duo.png"),
        os.path.join(IMAGES_DIR, "categories/stretching.png"),
        os.path.join(IMAGES_DIR, "categories/stretching.jpg"),
        box=(0, 0, 840, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Stretching and Meditation Fitness Duo.png"),
        os.path.join(IMAGES_DIR, "categories/meditation.png"),
        os.path.join(IMAGES_DIR, "categories/meditation.jpg"),
        box=(840, 0, 830, 941)
    )
    
    # Gym Workout from Still Life
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon-Accented Gym Gear Still Life.png"),
        os.path.join(IMAGES_DIR, "categories/gym_workout.png"),
        os.path.join(IMAGES_DIR, "categories/gym_workout.jpg")
    )
    
    # Nutrition & Recovery Categories
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Nutrition and Recovery Fitness Banners.png"),
        os.path.join(IMAGES_DIR, "categories/nutrition.png"),
        os.path.join(IMAGES_DIR, "categories/nutrition.jpg"),
        box=(0, 0, 835, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Nutrition and Recovery Fitness Banners.png"),
        os.path.join(IMAGES_DIR, "categories/recovery.png"),
        os.path.join(IMAGES_DIR, "categories/recovery.jpg"),
        box=(835, 0, 836, 941)
    )
    
    # Neon Fitness Category Icon Sheet (1536 x 1024) -> 8 Individual Badges
    icon_sheet = os.path.join(ASSETS_DIR, "Neon Fitness Category Icon Sheet.png")
    badges = [
        ("badge_strength.png", (0, 0, 384, 512)),
        ("badge_cardio.png", (384, 0, 384, 512)),
        ("badge_hiit.png", (768, 0, 384, 512)),
        ("badge_yoga.png", (1152, 0, 384, 512)),
        ("badge_bodyweight.png", (0, 512, 384, 512)),
        ("badge_mobility.png", (384, 512, 384, 512)),
        ("badge_nutrition.png", (768, 512, 384, 512)),
        ("badge_recovery.png", (1152, 512, 384, 512)),
    ]
    for b_name, b_box in badges:
        copy_or_crop(icon_sheet, os.path.join(IMAGES_DIR, "categories", b_name), box=b_box)
        
    # ----------------------------------------------------
    # 2. WORKOUTS
    # ----------------------------------------------------
    print("\n--- Processing Workouts ---")
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon-Edge Dumbbell Workout.png"),
        os.path.join(IMAGES_DIR, "workouts/strength_hero.png"),
        os.path.join(IMAGES_DIR, "workouts/strength_hero.jpg")
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon-Edge Dumbbell Workout.png"),
        os.path.join(IMAGES_DIR, "workouts/today_workout_athlete.png"),
        os.path.join(IMAGES_DIR, "workouts/today_workout_athlete.jpg"),
        box=(380, 0, 850, 941)
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon-Accented Gym Gear Still Life.png"),
        os.path.join(IMAGES_DIR, "workouts/gym_workout.png"),
        os.path.join(IMAGES_DIR, "workouts/gym_workout.jpg")
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Real Workouts, Real Results.png"),
        os.path.join(IMAGES_DIR, "workouts/battle_ropes.png"),
        os.path.join(IMAGES_DIR, "workouts/battle_ropes.jpg")
    )
    
    # Workout Category Thumbnails (matching category cards)
    for cat in ["strength", "cardio", "hiit", "yoga", "bodyweight", "mobility", "running", "cycling", "stretching", "meditation"]:
        shutil.copy(os.path.join(IMAGES_DIR, f"categories/{cat}.png"), os.path.join(IMAGES_DIR, f"workouts/{cat}.png"))
        shutil.copy(os.path.join(IMAGES_DIR, f"categories/{cat}.jpg"), os.path.join(IMAGES_DIR, f"workouts/{cat}.jpg"))

    # ----------------------------------------------------
    # 3. EXERCISES & ANATOMY
    # ----------------------------------------------------
    print("\n--- Processing Exercises & Anatomy ---")
    # Push Ups (1774 x 887)
    pushup_src = os.path.join(ASSETS_DIR, "Push-Up Muscle Activation Guide.png")
    copy_or_crop(pushup_src, os.path.join(IMAGES_DIR, "exercises/push_ups.png"))
    copy_or_crop(pushup_src, os.path.join(IMAGES_DIR, "exercises/anatomy_chest.png"))
    copy_or_crop(pushup_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_chest.png"))
    copy_or_crop(pushup_src, os.path.join(IMAGES_DIR, "exercises/push_up_top.png"), box=(0, 0, 950, 887))
    copy_or_crop(pushup_src, os.path.join(IMAGES_DIR, "exercises/push_up_bottom.png"), box=(850, 0, 924, 887))

    # Core Plank (1774 x 887)
    plank_src = os.path.join(ASSETS_DIR, "Glowing Core Plank Anatomy Illustration.png")
    copy_or_crop(plank_src, os.path.join(IMAGES_DIR, "exercises/plank.png"))
    copy_or_crop(plank_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_core.png"))
    copy_or_crop(plank_src, os.path.join(IMAGES_DIR, "exercises/anatomy_core.png"))

    # Bench Press (1536 x 1024)
    bench_src = os.path.join(ASSETS_DIR, "Anatomical Bench Press Progression.png")
    copy_or_crop(bench_src, os.path.join(IMAGES_DIR, "exercises/bench_press.png"))
    copy_or_crop(bench_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_bench.png"))
    copy_or_crop(bench_src, os.path.join(IMAGES_DIR, "exercises/bench_press_bottom.png"), box=(0, 0, 780, 1024))
    copy_or_crop(bench_src, os.path.join(IMAGES_DIR, "exercises/bench_press_top.png"), box=(750, 0, 786, 1024))

    # Barbell Squat (1536 x 1024)
    squat_src = os.path.join(ASSETS_DIR, "Anatomical Barbell Squat Comparison-2.png")
    copy_or_crop(squat_src, os.path.join(IMAGES_DIR, "exercises/squats.png"))
    copy_or_crop(squat_src, os.path.join(IMAGES_DIR, "exercises/anatomy_legs.png"))
    copy_or_crop(squat_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_legs.png"))
    copy_or_crop(squat_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_squat.png"))
    copy_or_crop(squat_src, os.path.join(IMAGES_DIR, "exercises/squat_standing.png"), box=(0, 0, 780, 1024))
    copy_or_crop(squat_src, os.path.join(IMAGES_DIR, "exercises/squat_deep.png"), box=(750, 0, 786, 1024))

    # Bodyweight Squats (1536 x 1024)
    bw_squat_src = os.path.join(ASSETS_DIR, "Standing and Squatting Muscle Guide-1.png")
    copy_or_crop(bw_squat_src, os.path.join(IMAGES_DIR, "exercises/bodyweight_squats.png"))
    copy_or_crop(bw_squat_src, os.path.join(IMAGES_DIR, "exercises/air_squat_standing.png"), box=(0, 0, 780, 1024))
    copy_or_crop(bw_squat_src, os.path.join(IMAGES_DIR, "exercises/air_squat_deep.png"), box=(750, 0, 786, 1024))

    # Lunges (1536 x 1024)
    lunge_src = os.path.join(ASSETS_DIR, "Anatomical Dumbbell Lunge Study.png")
    copy_or_crop(lunge_src, os.path.join(IMAGES_DIR, "exercises/lunges.png"))
    copy_or_crop(lunge_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_lunges.png"))
    copy_or_crop(lunge_src, os.path.join(IMAGES_DIR, "exercises/lunge_start.png"), box=(0, 0, 750, 1024))
    copy_or_crop(lunge_src, os.path.join(IMAGES_DIR, "exercises/lunge_deep.png"), box=(700, 0, 836, 1024))

    # Deadlift (1536 x 1024)
    deadlift_src = os.path.join(ASSETS_DIR, "Deadlift Anatomy_ Start to Lockout.png")
    copy_or_crop(deadlift_src, os.path.join(IMAGES_DIR, "exercises/deadlift.png"))
    copy_or_crop(deadlift_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_deadlift.png"))
    copy_or_crop(deadlift_src, os.path.join(IMAGES_DIR, "exercises/deadlift_start.png"), box=(0, 0, 800, 1024))
    copy_or_crop(deadlift_src, os.path.join(IMAGES_DIR, "exercises/deadlift_lockout.png"), box=(730, 0, 806, 1024))

    # Pull-Ups (1536 x 1024)
    pullup_src = os.path.join(ASSETS_DIR, "Anatomy of the Pull-Up.png")
    copy_or_crop(pullup_src, os.path.join(IMAGES_DIR, "exercises/pull_ups.png"))
    copy_or_crop(pullup_src, os.path.join(IMAGES_DIR, "exercises/anatomy_back.png"))
    copy_or_crop(pullup_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_back.png"))
    copy_or_crop(pullup_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_pullup.png"))
    copy_or_crop(pullup_src, os.path.join(IMAGES_DIR, "exercises/pull_up_hang.png"), box=(0, 0, 760, 1024))
    copy_or_crop(pullup_src, os.path.join(IMAGES_DIR, "exercises/pull_up_top.png"), box=(760, 0, 776, 1024))

    # Dumbbell Row (1536 x 1024)
    row_src = os.path.join(ASSETS_DIR, "Dumbbell Row Anatomy Comparison.png")
    copy_or_crop(row_src, os.path.join(IMAGES_DIR, "exercises/dumbbell_row.png"))
    copy_or_crop(row_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_row.png"))
    copy_or_crop(row_src, os.path.join(IMAGES_DIR, "exercises/row_stretch.png"), box=(0, 0, 780, 1024))
    copy_or_crop(row_src, os.path.join(IMAGES_DIR, "exercises/row_pull.png"), box=(750, 0, 786, 1024))

    # Shoulder Press (1536 x 1024)
    shoulder_src = os.path.join(ASSETS_DIR, "Dumbbell Shoulder Press Anatomy_ Start to Finish.png")
    copy_or_crop(shoulder_src, os.path.join(IMAGES_DIR, "exercises/shoulder_press.png"))
    copy_or_crop(shoulder_src, os.path.join(IMAGES_DIR, "exercises/anatomy_shoulders.png"))
    copy_or_crop(shoulder_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_shoulders.png"))
    copy_or_crop(shoulder_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_shoulder_press.png"))
    copy_or_crop(shoulder_src, os.path.join(IMAGES_DIR, "exercises/shoulder_press_start.png"), box=(0, 0, 780, 1024))
    copy_or_crop(shoulder_src, os.path.join(IMAGES_DIR, "exercises/shoulder_press_lockout.png"), box=(750, 0, 786, 1024))

    # Bicep Curl & Full Body (1254 x 1254 & 1024 x 1536)
    curl_src = os.path.join(ASSETS_DIR, "Anatomical Dumbbell Curl Illustration.png")
    copy_or_crop(curl_src, os.path.join(IMAGES_DIR, "exercises/bicep_curl.png"))
    copy_or_crop(curl_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_biceps.png"))
    copy_or_crop(curl_src, os.path.join(IMAGES_DIR, "exercises/anatomy_biceps.png"))

    figure_src = os.path.join(ASSETS_DIR, "Grayscale Anatomy Biceps Dumbbell Figure.png")
    copy_or_crop(figure_src, os.path.join(IMAGES_DIR, "anatomy/anatomy_full_body.png"))

    # ----------------------------------------------------
    # 4. NUTRITION
    # ----------------------------------------------------
    print("\n--- Processing Nutrition ---")
    nutr_src = os.path.join(ASSETS_DIR, "Nutrition and Recovery Fitness Banners.png")
    copy_or_crop(
        nutr_src,
        os.path.join(IMAGES_DIR, "nutrition/healthy_meal.png"),
        os.path.join(IMAGES_DIR, "nutrition/healthy_meal.jpg"),
        box=(0, 0, 835, 941)
    )
    copy_or_crop(
        nutr_src,
        os.path.join(IMAGES_DIR, "nutrition/sleep_recovery.png"),
        os.path.join(IMAGES_DIR, "nutrition/sleep_recovery.jpg"),
        box=(835, 0, 836, 941)
    )
    # Fresh ingredients zoom
    copy_or_crop(
        nutr_src,
        os.path.join(IMAGES_DIR, "nutrition/fresh_ingredients.png"),
        os.path.join(IMAGES_DIR, "nutrition/fresh_ingredients.jpg"),
        box=(10, 380, 500, 500)
    )
    # Hydration
    gear_src = os.path.join(ASSETS_DIR, "Neon-Accented Gym Gear Still Life.png")
    copy_or_crop(
        gear_src,
        os.path.join(IMAGES_DIR, "nutrition/hydration.png"),
        os.path.join(IMAGES_DIR, "nutrition/hydration.jpg"),
        box=(550, 350, 450, 591)
    )
    # Restore vegan burrito
    backup_burrito = "build/vegan_burrito_backup.jpg"
    if os.path.exists(backup_burrito):
        shutil.copy(backup_burrito, os.path.join(IMAGES_DIR, "nutrition/vegan_burrito.jpg"))
        shutil.copy(backup_burrito, os.path.join(IMAGES_DIR, "nutrition/vegan_burrito.png"))

    # ----------------------------------------------------
    # 5. ONBOARDING
    # ----------------------------------------------------
    print("\n--- Processing Onboarding ---")
    onboarding_banners = [
        ("A Healthier, Happier You.png", "banner_healthier"),
        ("Better Habits, Brighter You.png", "banner_habits"),
        ("Fit Stronger Tomorrow.png", "banner_stronger"),
        ("Real Workouts, Real Results.png", "banner_results"),
        ("Strength Builds a Better You.png", "banner_build"),
        ("Train Smarter, Not Harder.png", "banner_smarter"),
    ]
    for src_file, dest_prefix in onboarding_banners:
        copy_or_crop(
            os.path.join(ASSETS_DIR, src_file),
            os.path.join(IMAGES_DIR, f"onboarding/{dest_prefix}.png"),
            os.path.join(IMAGES_DIR, f"onboarding/{dest_prefix}.jpg")
        )
        
    # Also banner_anytime.jpg / hero_strength.jpg
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Better Habits, Brighter You.png"),
        os.path.join(IMAGES_DIR, "onboarding/banner_anytime.png"),
        os.path.join(IMAGES_DIR, "onboarding/banner_anytime.jpg")
    )
    copy_or_crop(
        os.path.join(ASSETS_DIR, "Neon-Edge Dumbbell Workout.png"),
        os.path.join(IMAGES_DIR, "onboarding/hero_strength.png"),
        os.path.join(IMAGES_DIR, "onboarding/hero_strength.jpg")
    )

    print("\nALL 27 SOURCE IMAGES PROCESSED, THEMED, AND CROPPED SUCCESSFULLY!")

if __name__ == "__main__":
    run()
