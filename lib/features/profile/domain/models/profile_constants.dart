/// Shared constants for Fit Host profile, wizard, and edit screens.
/// Single source of truth for goals, focus areas, and gender-specific targets.
library;

const List<String> kFitnessGoals = [
  'Lose Weight',
  'Build Muscle',
  'Recomp',
  'Maintain',
];

const List<String> kFocusAreas = [
  'Full Body',
  'Chest',
  'Back',
  'Arms',
  'Abs/Core',
  'Legs',
  'Glutes',
  'Shoulders',
  'Flexibility',
];

/// Gender-specific target focus areas with up to 10 body parts each.
const List<String> kMaleFocusAreas = [
  'Full Body',
  'Shoulders & Delts',
  'Chest',
  'Biceps & Arms',
  'Upper Back & Lats',
  'Abs & Six-Pack',
  'Obliques & Core',
  'Triceps & Forearms',
  'Glutes & Hamstrings',
  'Quads & Thighs',
  'Calves & Lower Legs',
];

const List<String> kFemaleFocusAreas = [
  'Full Body',
  'Arms & Shoulders',
  'Chest & Decollete',
  'Back & Posture',
  'Abs & Flat Belly',
  'Waist & Hourglass',
  'Hips & Pelvis',
  'Glutes & Booty',
  'Hamstrings & Adductors',
  'Thighs & Quads',
  'Calves & Ankles',
];

List<String> getFocusAreasForGender(String gender) {
  if (gender.toLowerCase() == 'female') {
    return kFemaleFocusAreas;
  }
  return kMaleFocusAreas;
}

const List<String> kMaleSpecificGoals = [
  'Upper chest development',
  'Shoulder width',
  'Arm size',
  'Back thickness (V-taper)',
  'Leg power',
  'Core strength',
];

const List<String> kFemaleSpecificGoals = [
  'Glute development',
  'Hip curves',
  'Waist definition',
  'Toned arms',
  'Thigh shaping',
  'Core strength',
  'Full body toning',
];

const List<String> kDietTypes = [
  'Vegetarian',
  'Non-Veg',
  'Eggetarian',
  'Vegan',
  'Pescatarian',
  'Other',
];

const List<String> kAvailableEquipment = [
  'Bodyweight',
  'Dumbbells',
  'Barbells',
  'Kettlebells',
  'Bands',
  'Pull-up Bar',
  'Cable Machine',
  'Full Gym',
];

const List<String> kTrainingLocations = [
  'Gym',
  'Home',
  'Outdoors',
];

const List<String> kExperienceLevels = [
  'Beginner',
  'Intermediate',
  'Advanced',
];

const List<String> kWeekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
