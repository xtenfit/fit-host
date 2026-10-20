import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get targetMuscle => text()();
  TextColumn get instructions => text()();
  TextColumn get equipment => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get imageAsset => text().nullable()();
  TextColumn get anatomyAsset => text().nullable()();
  TextColumn get recommendedFor => text().withDefault(const Constant('all'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox synchronization queue table (schema version 3).
/// Migrated in-place under the original table name `sync_queue`.
@TableIndex(name: 'idx_sync_queue_status_attempts', columns: {#status, #attempts})
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant('guest'))();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'INSERT', 'UPDATE', 'DELETE', 'upsert'
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
  TextColumn get source =>
      text().withDefault(const Constant('seeded'))(); // seeded, openfoodfacts, gemini, user_custom
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
  TextColumn get category => text().withDefault(const Constant('work'))(); // 'work', 'professional', 'fitness', 'personal', 'ideas'
  TextColumn get mood => text().withDefault(const Constant('focused'))(); // 'focused', 'productive', 'energized', 'calm', 'tired'
  TextColumn get voiceMemoPath => text().nullable()();
  IntColumn get voiceMemoDurationSeconds => integer().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
