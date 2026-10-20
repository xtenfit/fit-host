import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database.dart' hide Reminder;
import '../../../../core/data/workout_repository.dart';
import '../../../../core/data/nutrition_repository.dart';
import '../../../../core/data/hydration_repository.dart';
import '../../../../core/data/steps_repository.dart';
import '../../../../core/data/reminder_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/day_summary.dart';

class DaySummaryService {
  final AppDatabase db;
  final WorkoutRepository workoutRepository;
  final NutritionRepository nutritionRepository;
  final HydrationRepository hydrationRepository;
  final StepsRepository stepsRepository;
  final ReminderRepository reminderRepository;
  final SupabaseClient? supabase;
  final String userId;

  DaySummaryService({
    required this.db,
    required this.workoutRepository,
    required this.nutritionRepository,
    required this.hydrationRepository,
    required this.stepsRepository,
    required this.reminderRepository,
    this.supabase,
    this.userId = 'guest',
  });

  /// Generates DST-safe list of calendar dates between [startDate] and [endDate] inclusive.
  /// Uses DateTime(year, month, day + 1) to naturally traverse 23h/25h DST boundaries.
  static List<DateTime> generateDateRange(DateTime startDate, DateTime endDate) {
    final List<DateTime> dates = [];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final targetEnd = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(targetEnd)) {
      dates.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return dates;
  }

  /// Batch query for a given date range.
  /// If signed in and online, attempts server RPC `get_day_summaries`.
  /// Falls back to 1 local batch query per repository and aggregates in Dart.
  Future<List<DaySummary>> getDaySummaries(DateTime startDate, DateTime endDate) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // 1. Try server RPC for authenticated users
    if (userId != 'guest' && supabase != null) {
      try {
        final startStr = DateFormat('yyyy-MM-dd').format(start);
        final endStr = DateFormat('yyyy-MM-dd').format(end);

        final response = await supabase!.rpc(
          'get_day_summaries',
          params: {
            'start_date': startStr,
            'end_date': endStr,
          },
        ).timeout(const Duration(milliseconds: 1500));

        if (response != null && response is List) {
          final serverSummaries = response
              .map((row) => DaySummary.fromRpc(row as Map<String, dynamic>))
              .toList();
          if (serverSummaries.isNotEmpty) {
            return serverSummaries;
          }
        }
      } catch (e) {
        debugPrint('[DaySummaryService] Server RPC fallback to local: $e');
      }
    }

    // 2. Local batch query across all repositories (1 query per repository)
    return _aggregateLocalRange(start, end);
  }

  /// Reactive watch stream across the date range.
  /// Emits new [DaySummary] list immediately whenever any underlying table mutates.
  Stream<List<DaySummary>> watchDaySummaries(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final controller = StreamController<List<DaySummary>>.broadcast();

    Future<void> emitLatest() async {
      if (controller.isClosed) return;
      try {
        final data = await _aggregateLocalRange(start, end);
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    emitLatest();

    final sub1 = (db.select(db.workouts)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.status.equals('completed') &
              t.startedAt.isBiggerOrEqualValue(start) &
              t.startedAt.isSmallerOrEqualValue(end)))
        .watch()
        .listen((_) => emitLatest(), onError: (_) {});

    final sub2 = (db.select(db.nutritionLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerOrEqualValue(end)))
        .watch()
        .listen((_) => emitLatest(), onError: (_) {});

    final sub3 = (db.select(db.hydrationLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerOrEqualValue(end)))
        .watch()
        .listen((_) => emitLatest(), onError: (_) {});

    final sub4 = (db.select(db.stepDailyLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.stepDate.isBiggerOrEqualValue(start) &
              t.stepDate.isSmallerOrEqualValue(end)))
        .watch()
        .listen((_) => emitLatest(), onError: (_) {});

    final sub5 = (db.select(db.reminders)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .watch()
        .listen((_) => emitLatest(), onError: (_) {});

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      sub4.cancel();
      sub5.cancel();
    };

    return controller.stream;
  }

  Future<List<DaySummary>> _aggregateLocalRange(DateTime start, DateTime end) async {
    final workouts = await (db.select(db.workouts)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.status.equals('completed') &
              t.startedAt.isBiggerOrEqualValue(start) &
              t.startedAt.isSmallerOrEqualValue(end)))
        .get();

    final nutritionLogs = await (db.select(db.nutritionLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerOrEqualValue(end)))
        .get();

    final hydrationLogs = await (db.select(db.hydrationLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerOrEqualValue(end)))
        .get();

    final stepLogs = await (db.select(db.stepDailyLogs)
          ..where((t) =>
              t.userId.equals(userId) &
              t.deletedAt.isNull() &
              t.stepDate.isBiggerOrEqualValue(start) &
              t.stepDate.isSmallerOrEqualValue(end)))
        .get();

    final reminders = await (db.select(db.reminders)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();

    return _combineIntoSummaries(
      start: start,
      end: end,
      workouts: workouts,
      nutritionLogs: nutritionLogs,
      hydrationLogs: hydrationLogs,
      stepLogs: stepLogs,
      reminders: reminders,
    );
  }

  List<DaySummary> _combineIntoSummaries({
    required DateTime start,
    required DateTime end,
    required List<Workout> workouts,
    required List<NutritionLog> nutritionLogs,
    required List<HydrationLog> hydrationLogs,
    required List<StepDailyLog> stepLogs,
    required List<dynamic> reminders,
  }) {
    final dateList = generateDateRange(start, end);

    // Group workouts by day key (yyyy-MM-dd)
    final Map<String, List<Workout>> workoutsByDay = {};
    for (final w in workouts) {
      final key = DateFormat('yyyy-MM-dd').format(w.startedAt);
      workoutsByDay.putIfAbsent(key, () => []).add(w);
    }

    // Group nutrition by day key
    final Map<String, NutritionLog> nutritionByDay = {};
    for (final n in nutritionLogs) {
      final key = DateFormat('yyyy-MM-dd').format(n.logDate);
      nutritionByDay[key] = n;
    }

    // Group hydration by day key
    final Map<String, HydrationLog> hydrationByDay = {};
    for (final h in hydrationLogs) {
      final key = DateFormat('yyyy-MM-dd').format(h.logDate);
      hydrationByDay[key] = h;
    }

    // Group steps by day key
    final Map<String, StepDailyLog> stepsByDay = {};
    for (final s in stepLogs) {
      final key = DateFormat('yyyy-MM-dd').format(s.stepDate);
      stepsByDay[key] = s;
    }

    final List<DaySummary> summaries = [];

    for (final d in dateList) {
      final dateKey = DateFormat('yyyy-MM-dd').format(d);

      // Workouts
      final dayWorkouts = workoutsByDay[dateKey] ?? [];
      final workoutCount = dayWorkouts.length;
      final workoutDurationMin = dayWorkouts.fold(
          0, (sum, w) => sum + (w.durationSeconds ~/ 60));
      // Calorie burn estimate: ~8 kcal/min for completed workouts
      final workoutCalories = workoutDurationMin * 8;

      // Nutrition
      final nutritionRow = nutritionByDay[dateKey];
      int calIn = 0;
      double protG = 0.0;
      double carbG = 0.0;
      double fatG = 0.0;
      int waterFromNutrition = 0;

      if (nutritionRow != null) {
        waterFromNutrition = nutritionRow.waterGlasses * 250;
        try {
          final mealsList = jsonDecode(nutritionRow.loggedMeals) as List<dynamic>;
          for (final m in mealsList) {
            final map = m as Map<String, dynamic>;
            calIn += (map['calories'] as num?)?.toInt() ?? 0;
            protG += (map['protein_grams'] as num?)?.toDouble() ?? 0.0;
            carbG += (map['carbs_grams'] as num?)?.toDouble() ?? 0.0;
            fatG += (map['fat_grams'] as num?)?.toDouble() ?? 0.0;
          }
        } catch (_) {}
      }

      // Hydration
      final hydrationRow = hydrationByDay[dateKey];
      final waterFromHydration = hydrationRow != null
          ? (hydrationRow.totalMl > 0
              ? hydrationRow.totalMl
              : hydrationRow.waterGlasses * 250)
          : 0;
      final totalWaterMl = waterFromHydration > 0 ? waterFromHydration : waterFromNutrition;

      // Steps
      final stepsRow = stepsByDay[dateKey];
      final stepsCount = stepsRow?.steps ?? 0;
      final distKm = (stepsRow?.distanceMeters ?? 0.0) / 1000.0;
      final stepCalories = stepsRow?.activeCalories ?? 0;

      // Reminders
      final hasReminder = reminders.isNotEmpty;
      int compReminders = 0;
      int missReminders = 0;
      for (final r in reminders) {
        if (r.lastCompletedAt != null) {
          final compKey = DateFormat('yyyy-MM-dd').format(r.lastCompletedAt!);
          if (compKey == dateKey) compReminders++;
        }
        if (r.isDismissed == true && r.lastTriggeredAt != null) {
          final trigKey = DateFormat('yyyy-MM-dd').format(r.lastTriggeredAt!);
          if (trigKey == dateKey) missReminders++;
        }
      }

      summaries.add(DaySummary(
        date: d,
        steps: stepsCount,
        distanceKm: distKm,
        workoutCount: workoutCount,
        workoutDurationMin: workoutDurationMin,
        caloriesBurned: workoutCalories + stepCalories,
        caloriesIn: calIn,
        proteinG: double.parse(protG.toStringAsFixed(1)),
        carbsG: double.parse(carbG.toStringAsFixed(1)),
        fatsG: double.parse(fatG.toStringAsFixed(1)),
        waterMl: totalWaterMl,
        hasReminder: hasReminder,
        completedReminders: compReminders,
        missedReminders: missReminders,
      ));
    }

    return summaries;
  }
}

final daySummaryServiceProvider = Provider<DaySummaryService>((ref) {
  final db = ref.watch(databaseProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);
  final hydrationRepo = ref.watch(hydrationRepositoryProvider);
  final stepsRepo = ref.watch(stepsRepositoryProvider);
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final auth = ref.watch(authProvider);

  final userId = auth.user?.id ?? 'guest';
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {}

  return DaySummaryService(
    db: db,
    workoutRepository: workoutRepo,
    nutritionRepository: nutritionRepo,
    hydrationRepository: hydrationRepo,
    stepsRepository: stepsRepo,
    reminderRepository: reminderRepo,
    supabase: client,
    userId: userId,
  );
});
