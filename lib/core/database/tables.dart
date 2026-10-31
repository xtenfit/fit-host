import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get canonicalId => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('fit-host'))();
  TextColumn get originalSourceId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get aliases => text().nullable()(); // JSON list
  TextColumn get category => text()();
  TextColumn get bodyPart => text().nullable()();
  TextColumn get targetMuscle => text()();
  TextColumn get muscleGroup => text().nullable()();
  TextColumn get secondaryMuscles => text().nullable()(); // JSON list
  TextColumn get instructions => text()();
  TextColumn get instructionSteps => text().nullable()(); // JSON list
  TextColumn get equipment => text()();
  TextColumn get exerciseType =>
      text().withDefault(const Constant('strength'))();
  TextColumn get movementType =>
      text().withDefault(const Constant('compound'))();
  TextColumn get difficultyLevel =>
      text().withDefault(const Constant('intermediate'))();
  TextColumn get audienceSuitability =>
      text().withDefault(const Constant('universal'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get imageAsset => text().nullable()();
  TextColumn get anatomyAsset => text().nullable()();
  TextColumn get mediaThumbnailUrl => text().nullable()();
  TextColumn get mediaAnimationUrl => text().nullable()();
  TextColumn get mediaLicense => text().nullable()();
  TextColumn get mediaAttribution => text().nullable()();
  TextColumn get contentLicense => text().nullable()();
  TextColumn get contentAttribution => text().nullable()();
  TextColumn get languagesAvailable => text().nullable()(); // JSON list
  TextColumn get safetyNotes => text().nullable()();
  TextColumn get publicationStatus =>
      text().withDefault(const Constant('published'))();
  TextColumn get recommendedFor => text().withDefault(const Constant('all'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseIdMappings extends Table {
  TextColumn get oldExerciseId => text()();
  TextColumn get canonicalExerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get oldName => text().nullable()();
  TextColumn get canonicalName => text().nullable()();
  TextColumn get confidence => text().withDefault(const Constant('high'))();
  DateTimeColumn get mappedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {oldExerciseId};
}

class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('in_progress'))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get caloriesBurned => integer().nullable()();
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get clientMutationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get supersetId => text().nullable()();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get weightKg => real().withDefault(const Constant(0.0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  IntColumn get targetReps => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  TextColumn get tempo => text().nullable()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('custom'))();
  TextColumn get difficulty =>
      text().withDefault(const Constant('intermediate'))();
  IntColumn get estimatedDurationMinutes =>
      integer().withDefault(const Constant(45))();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineExercises extends Table {
  TextColumn get id => text()();
  TextColumn get routineId =>
      text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get supersetId => text().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineSets extends Table {
  TextColumn get id => text()();
  TextColumn get routineExerciseId =>
      text().references(RoutineExercises, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  IntColumn get setNumber => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  IntColumn get targetReps => integer().withDefault(const Constant(10))();
  RealColumn get targetWeightKg => real().nullable()();
  IntColumn get targetDurationSeconds => integer().nullable()();
  RealColumn get targetDistanceMeters => real().nullable()();
  RealColumn get targetRpe => real().nullable()();
  TextColumn get tempo => text().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get recordType =>
      text()(); // 'max_weight', 'estimated_1rm', 'max_reps', 'max_volume_set', 'max_volume_workout'
  RealColumn get value => real()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get workoutId => text().nullable()();
  TextColumn get workoutSetId => text().nullable()();
  DateTimeColumn get achievedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProgressionSettings extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get strategy =>
      text().withDefault(const Constant('double_progression'))();
  IntColumn get targetRepsMin => integer().withDefault(const Constant(8))();
  IntColumn get targetRepsMax => integer().withDefault(const Constant(12))();
  IntColumn get targetWorkingSets => integer().withDefault(const Constant(3))();
  IntColumn get successfulSessionsRequired =>
      integer().withDefault(const Constant(2))();
  RealColumn get weightIncrementKg => real().withDefault(const Constant(2.5))();
  TextColumn get unitSystem => text().withDefault(const Constant('kg'))();
  BoolColumn get autoApply => boolean().withDefault(const Constant(false))();
  IntColumn get deloadAfterMissedSessions =>
      integer().withDefault(const Constant(3))();
  RealColumn get deloadPercentage => real().withDefault(const Constant(10.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox synchronization queue table (schema version 3).
/// Migrated in-place under the original table name `sync_queue`.
@TableIndex(
  name: 'idx_sync_queue_status_attempts',
  columns: {#status, #attempts},
)
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation =>
      text()(); // 'INSERT', 'UPDATE', 'DELETE', 'upsert'
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get clientTimestamp =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get errorLog => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirrors Postgres public.nutrition_logs (one row per user_id, log_date).
class NutritionLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  DateTimeColumn get logDate => dateTime()();
  IntColumn get targetCalories => integer().withDefault(const Constant(2250))();
  IntColumn get targetProtein => integer().withDefault(const Constant(145))();
  IntColumn get targetCarbs => integer().withDefault(const Constant(250))();
  IntColumn get targetFat => integer().withDefault(const Constant(60))();
  IntColumn get targetWaterGlasses =>
      integer().withDefault(const Constant(10))();
  IntColumn get waterGlasses => integer().withDefault(const Constant(0))();
  TextColumn get loggedMeals =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get loggedDrinks =>
      text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get eventType => text()(); // 'workout', 'rest_day', etc.
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isMissed => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().withDefault(const Constant('none'))();
  TextColumn get targetMetrics => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get timeOfDay => text()(); // 'HH:mm'
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get recurrence => text().withDefault(const Constant('daily'))();
  TextColumn get repeatDays => text().nullable()();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get vibrationEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get snoozeDurationMinutes =>
      integer().withDefault(const Constant(10))();
  DateTimeColumn get lastTriggeredAt => dateTime().nullable()();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  BoolColumn get isDismissed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();
  TextColumn get deliveryMode => text().withDefault(const Constant('alarm'))();

  @override
  Set<Column> get primaryKey => {id};
}

class HydrationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  DateTimeColumn get logDate => dateTime()();
  IntColumn get waterGlasses => integer().withDefault(const Constant(0))();
  IntColumn get targetGlasses => integer().withDefault(const Constant(10))();
  IntColumn get totalMl => integer().withDefault(const Constant(0))();
  TextColumn get drinkType => text().withDefault(const Constant('water'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StepDailyLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  DateTimeColumn get stepDate => dateTime()();
  IntColumn get steps => integer().withDefault(const Constant(0))();
  IntColumn get targetSteps => integer().withDefault(const Constant(10000))();
  RealColumn get distanceMeters => real().withDefault(const Constant(0.0))();
  IntColumn get activeCalories => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FoodItemData')
@TableIndex(name: 'idx_food_items_barcode', columns: {#barcode})
class FoodItems extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  RealColumn get proteinPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get carbsPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get fatsPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get caloriesPer100g => real().withDefault(const Constant(0.0))();
  TextColumn get servingPresetsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get source => text().withDefault(
    const Constant('seeded'),
  )(); // seeded, openfoodfacts, gemini, user_custom
  TextColumn get imageUrl => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().withDefault(const Constant('guest'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyDiaryEntry')
class DailyDiaryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get category => text().withDefault(
    const Constant('work'),
  )(); // 'work', 'professional', 'fitness', 'personal', 'ideas'
  TextColumn get mood => text().withDefault(
    const Constant('focused'),
  )(); // 'focused', 'productive', 'energized', 'calm', 'tired'
  TextColumn get voiceMemoPath => text().nullable()();
  IntColumn get voiceMemoDurationSeconds => integer().nullable()();
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Part 4: Body measurements & anthropometric progression tracking
@DataClassName('BodyMeasurementData')
class BodyMeasurements extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPercentage => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get hipsCm => real().nullable()();
  RealColumn get armsCm => real().nullable()();
  RealColumn get thighsCm => real().nullable()();
  RealColumn get calvesCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get shouldersCm => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Part 4: Visual physique progress photos & side-by-side comparison gallery
@DataClassName('ProgressPhotoData')
class ProgressPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get photoPath => text()();
  TextColumn get poseType => text().withDefault(
    const Constant('front'),
  )(); // 'front', 'side', 'back', 'other'
  TextColumn get associatedMeasurementId => text().nullable().references(
    BodyMeasurements,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get weightKgAtPhoto => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Phase E: Exercise Wiki & Community Contribution Submissions
@DataClassName('ExerciseSubmissionData')
class ExerciseSubmissions extends Table {
  TextColumn get id => text()();
  TextColumn get submissionType => text().withDefault(
    const Constant('new_exercise'),
  )(); // 'new_exercise' | 'correction'
  TextColumn get targetExerciseId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get equipment => text()();
  TextColumn get targetMuscle => text()();
  TextColumn get secondaryMuscles =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get instructions => text()();
  TextColumn get safetyNotes => text().nullable()();
  TextColumn get difficultyLevel =>
      text().withDefault(const Constant('Intermediate'))();
  TextColumn get movementType =>
      text().withDefault(const Constant('Compound'))();
  TextColumn get audienceSuitability =>
      text().withDefault(const Constant('universal'))();
  TextColumn get suggestedRationale => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // 'pending' | 'approved' | 'rejected'
  TextColumn get moderatorNotes => text().nullable()();
  TextColumn get submittedBy => text().withDefault(const Constant('guest'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get duplicateHash => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Phase E: Exercise Wiki & Community Contribution Moderation Logs
@DataClassName('ExerciseModerationLogData')
class ExerciseModerationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get submissionId => text().references(
    ExerciseSubmissions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get moderatorId => text()();
  TextColumn get action => text()(); // 'approve' | 'reject' | 'request_changes'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notification Center: In-app notification inbox items
@DataClassName('NotificationInboxData')
class NotificationInboxItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get category => text().withDefault(
    const Constant('general'),
  )(); // 'workout', 'nutrition', 'hydration', 'step_goal', 'reminder', 'system'
  TextColumn get actionRoute => text().nullable()();
  TextColumn get actionPayload => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text().withDefault(
    const Constant('normal'),
  )(); // 'low', 'normal', 'high', 'urgent'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
