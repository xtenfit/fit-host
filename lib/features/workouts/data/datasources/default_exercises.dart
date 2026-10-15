import '../../domain/models/workout_models.dart';

final defaultExercisesList = [
  ExerciseEntity(
    id: 'ex-bench-press',
    name: 'Barbell Bench Press',
    category: 'Chest',
    targetMuscle: 'Pectoralis Major, Triceps',
    instructions:
        'Lie flat on the bench. Grip the barbell slightly wider than shoulder-width. Lower the bar smoothly to your mid-chest, then press upward explosively until arms are extended.',
    equipment: 'Barbell & Bench',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-incline-db-press',
    name: 'Incline Dumbbell Press',
    category: 'Chest',
    targetMuscle: 'Upper Chest, Anterior Deltoid',
    instructions:
        'Set bench to 30-45 degrees. Hold dumbbells at shoulder level with palms facing forward. Press up until arms are fully extended, then lower with control.',
    equipment: 'Dumbbells & Incline Bench',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-barbell-squat',
    name: 'Barbell Back Squat',
    category: 'Legs',
    targetMuscle: 'Quadriceps, Glutes, Core',
    instructions:
        'Rest bar across upper back. Stand with feet shoulder-width apart. Hinge at hips and knees to lower until thighs are parallel to the floor. Drive up through midfoot.',
    equipment: 'Barbell & Squat Rack',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-romanian-deadlift',
    name: 'Romanian Deadlift',
    category: 'Legs',
    targetMuscle: 'Hamstrings, Glutes, Lower Back',
    instructions:
        'Hold bar at hip height. Keep slight bend in knees, push hips back, and lower bar along shins while maintaining a flat back. Squeeze glutes to return upright.',
    equipment: 'Barbell',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-deadlift',
    name: 'Conventional Deadlift',
    category: 'Back',
    targetMuscle: 'Entire Posterior Chain, Erector Spinae',
    instructions:
        'Stand with feet hip-width under bar. Grip bar just outside legs. Flatten spine, engage lats, and pull through the floor until hips and knees lock out.',
    equipment: 'Barbell & Plates',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-pullup',
    name: 'Pull-Up',
    category: 'Back',
    targetMuscle: 'Latissimus Dorsi, Biceps',
    instructions:
        'Grip bar with hands wider than shoulders, palms facing away. Pull your chest toward the bar by driving elbows down and back. Lower with control.',
    equipment: 'Pull-Up Bar',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-barbell-row',
    name: 'Bent-Over Barbell Row',
    category: 'Back',
    targetMuscle: 'Lats, Rhomboids, Traps',
    instructions:
        'Hinge forward at 45 degrees with flat spine. Pull bar towards lower abdomen, pinching shoulder blades together at top. Lower under control.',
    equipment: 'Barbell',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-overhead-press',
    name: 'Overhead Barbell Press',
    category: 'Shoulders',
    targetMuscle: 'Anterior & Lateral Deltoids, Triceps',
    instructions:
        'Stand with core braced and glutes squeezed. Press barbell from collarbone straight overhead until elbows lock out. Lower back smoothly to upper chest.',
    equipment: 'Barbell',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-lateral-raise',
    name: 'Dumbbell Lateral Raise',
    category: 'Shoulders',
    targetMuscle: 'Lateral Deltoids',
    instructions:
        'Stand tall holding dumbbells at sides. Raise arms out to the side until parallel with floor, leading with elbows. Pause briefly and lower with control.',
    equipment: 'Dumbbells',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-bicep-curl',
    name: 'Dumbbell Bicep Curl',
    category: 'Arms',
    targetMuscle: 'Biceps Brachii',
    instructions:
        'Keep elbows glued to sides. Curl weights upward while supinating wrists. Squeeze biceps at peak contraction and lower slowly.',
    equipment: 'Dumbbells',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-tricep-pushdown',
    name: 'Cable Tricep Pushdown',
    category: 'Arms',
    targetMuscle: 'Triceps Brachii',
    instructions:
        'Grip cable rope or straight bar at chest height. Keep upper arms stationary against torso and push downward until elbows fully extend. Return slowly.',
    equipment: 'Cable Machine',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ExerciseEntity(
    id: 'ex-plank',
    name: 'Core Plank',
    category: 'Core',
    targetMuscle: 'Transverse Abdominis, Obliques',
    instructions:
        'Hold push-up position on forearms. Form a straight line from crown of head to heels. Brace core, engage glutes, and breathe steadily.',
    equipment: 'Bodyweight',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
];
