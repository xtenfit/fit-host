import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/data/repositories/user_profile_repository.dart';

export '../../features/profile/domain/models/user_profile.dart';
export '../../features/profile/data/repositories/user_profile_repository.dart';

class LocalProfileRepository implements UserProfileRepository {
  final UserProfileRepositoryImpl _impl = UserProfileRepositoryImpl();

  @override
  Future<UserProfile> loadProfile() => _impl.loadProfile();

  @override
  Future<void> saveProfile(UserProfile profile) => _impl.saveProfile(profile);

  @override
  Future<void> resetProfile() => _impl.resetProfile();
}

class CloudProfileRepository implements UserProfileRepository {
  final AppDatabase db;
  final SupabaseClient? supabase;
  final String userId;
  final LocalProfileRepository _local = LocalProfileRepository();

  CloudProfileRepository({
    required this.db,
    required this.userId,
    this.supabase,
  });

  @override
  Future<UserProfile> loadProfile() async {
    final cached = await _local.loadProfile();
    _backgroundRefresh().ignore();
    return cached;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _local.saveProfile(profile);

    final payload = {
      'id': userId,
      'display_name': profile.name,
      'gender': profile.gender,
      'age': profile.age,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'target_weight_kg': profile.targetWeightKg,
      'fitness_goal': profile.fitnessGoal,
      'diet_type': profile.dietType,
      'daily_calories_target': profile.dailyCaloriesTarget,
      'target_protein_grams': profile.targetProteinGrams,
      'target_carbs_grams': profile.targetCarbsGrams,
      'target_fats_grams': profile.targetFatsGrams,
      'target_water_ml': profile.targetWaterMl,
      'weekly_workout_days': profile.weeklyWorkoutDays,
      'daily_workout_minutes': profile.dailyWorkoutMinutes,
      'is_profile_setup_completed': profile.isProfileSetupCompleted,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (supabase != null) {
      try {
        await supabase!.from('profiles').upsert(payload, onConflict: 'id');
        return;
      } catch (e) {
        debugPrint('[CloudProfileRepository] Upsert error: $e');
      }
    }

    await db.into(db.syncQueue).insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'sync_profile_$userId',
            userId: drift.Value(userId),
            entityType: 'profiles',
            entityId: userId,
            operation: 'upsert',
            payload: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
            clientTimestamp: drift.Value(DateTime.now().toUtc()),
            status: const drift.Value('queued'),
          ),
        );
  }

  @override
  Future<void> resetProfile() => _local.resetProfile();

  Future<void> _backgroundRefresh() async {
    if (supabase == null) return;
    try {
      final row = await supabase!
          .from('profiles')
          .select()
          .match({'id': userId})
          .maybeSingle();

      if (row != null) {
        final profile = UserProfile(
          name: row['display_name'] as String? ?? 'Athlete',
          age: row['age'] as int? ?? 26,
          gender: row['gender'] as String? ?? 'male',
          heightCm: (row['height_cm'] as num?)?.toDouble() ?? 175.0,
          weightKg: (row['weight_kg'] as num?)?.toDouble() ?? 72.0,
          targetWeightKg: (row['target_weight_kg'] as num?)?.toDouble() ?? 70.0,
          fitnessGoal: row['fitness_goal'] as String? ?? 'maintain_weight',
          dietType: row['diet_type'] as String? ?? 'balanced',
          dailyCaloriesTarget: row['daily_calories_target'] as int? ?? 2250,
          targetProteinGrams: row['target_protein_grams'] as int? ?? 145,
          targetCarbsGrams: row['target_carbs_grams'] as int? ?? 250,
          targetFatsGrams: row['target_fats_grams'] as int? ?? 60,
          targetWaterMl: row['target_water_ml'] as int? ?? 2500,
          weeklyWorkoutDays: row['weekly_workout_days'] as int? ?? 4,
          dailyWorkoutMinutes: row['daily_workout_minutes'] as int? ?? 45,
          customTargetNote: row['custom_target_note'] as String?,
          isProfileSetupCompleted: row['is_profile_setup_completed'] as bool? ?? true,
          updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
        );
        await _local.saveProfile(profile);
      }
    } catch (_) {}
  }
}

final profileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final status = ref.watch(authProvider).status;
  final db = ref.watch(databaseProvider);

  if (status == AuthStatus.authenticated) {
    final user = ref.watch(authProvider).user;
    if (user != null) {
      SupabaseClient? client;
      try {
        client = Supabase.instance.client;
      } catch (_) {}
      return CloudProfileRepository(
        db: db,
        userId: user.id,
        supabase: client,
      );
    }
  }

  return LocalProfileRepository();
});
