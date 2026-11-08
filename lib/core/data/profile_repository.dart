import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../services/supabase_service.dart';
import '../services/profile_avatar_service.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/data/repositories/user_profile_repository.dart';

export '../../features/profile/domain/models/user_profile.dart';
export '../../features/profile/data/repositories/user_profile_repository.dart';

class LocalProfileRepository implements UserProfileRepository {
  final UserProfileRepositoryImpl _impl;

  LocalProfileRepository({String? userId})
    : _impl = UserProfileRepositoryImpl(userId: userId);

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
  final LocalProfileRepository _local;

  CloudProfileRepository({
    required this.db,
    required this.userId,
    this.supabase,
  }) : _local = LocalProfileRepository(userId: userId);

  @override
  Future<UserProfile> loadProfile() async {
    final cached = await _local.loadProfile();
    if (!cached.isProfileSetupCompleted && supabase != null) {
      try {
        final remote = await _fetchRemoteProfile(cached);
        if (remote != null) {
          await _local.saveProfile(remote);
          return remote;
        }
      } catch (e) {
        debugPrint('[CloudProfileRepository] Initial remote fetch error: $e');
      }
    } else {
      _backgroundRefresh().ignore();
    }
    return cached;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _local.saveProfile(profile);

    final userEmail = supabase?.auth.currentUser?.email ?? 'user@fithost.app';

    // Synchronize avatar image if user keeps their own profile photo
    String? cloudAvatarUrl = profile.avatarId;
    if (ProfileAvatarService.isCustomDeviceAvatar(profile.avatarId)) {
      final uploadedUrl = await ProfileAvatarService.syncAvatarToRemoteStorage(
        userId: userId,
        localOrRemotePath: profile.avatarId,
        client: supabase,
      );
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        cloudAvatarUrl = uploadedUrl;
      }
    } else {
      // Bundled asset or monogram: do NOT upload to cloud storage
      cloudAvatarUrl = profile.avatarId;
    }

    final payload = {
      'id': userId,
      'email': userEmail,
      'display_name': profile.name,
      'avatar_url': cloudAvatarUrl,
      'gender': (profile.gender.isNotEmpty) ? profile.gender : 'other',
      'age': (profile.age > 0) ? profile.age : null,
      'height_cm': (profile.heightCm > 0) ? profile.heightCm : null,
      'weight_kg': (profile.weightKg > 0) ? profile.weightKg : null,
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
      'custom_target_note': profile.customTargetNote,
      // Wizard expansion & personalization fields
      'gender_specific_goals': jsonEncode(profile.genderSpecificGoals),
      'body_fat_percent': profile.bodyFatPercentage,
      'waist_cm': profile.waistCm,
      'hip_cm': profile.hipCm,
      'chest_cm': profile.chestCm,
      'neck_cm': profile.neckCm,
      'target_weeks': profile.targetWeeks,
      'selected_weekdays': jsonEncode(profile.selectedWeekdays),
      'session_duration_minutes': profile.sessionDurationMinutes,
      'uses_every_day': profile.usesEveryDay,
      'meals_per_day': profile.mealsPerDay,
      'sleep_hours': profile.targetSleepHours,
      'stress_level': profile.stressLevel,
      'reminder_frequency_hours': profile.reminderFrequencyHours,
      'quiet_hours_start': profile.quietHoursStart,
      'quiet_hours_end': profile.quietHoursEnd,
      'activity_level': profile.activityLevel,
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

    await db
        .into(db.syncQueue)
        .insertOnConflictUpdate(
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

  Future<UserProfile?> _fetchRemoteProfile(UserProfile cached) async {
    if (supabase == null) return null;
    try {
      final row = await supabase!
          .from('profiles')
          .select()
          .match({'id': userId})
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (row != null) {
        final avatar = row['avatar_url'] as String?;

        // If local profile already points to an existing custom device photo, retain it
        final isLocalCustomFile =
            ProfileAvatarService.isCustomDeviceAvatar(cached.avatarId) &&
            File(cached.avatarId).existsSync();
        final resolvedAvatarId = isLocalCustomFile
            ? cached.avatarId
            : ((avatar != null && avatar.isNotEmpty && avatar != 'initial')
                  ? avatar
                  : cached.avatarId);

        final heightVal = row['height_cm'] as num?;
        final isSetupDone =
            (row['is_profile_setup_completed'] as bool?) == true ||
            (heightVal != null && heightVal > 0);

        return cached.copyWith(
          name: row['display_name'] as String? ?? cached.name,
          age: row['age'] as int? ?? cached.age,
          gender: row['gender'] as String? ?? cached.gender,
          heightCm: (row['height_cm'] as num?)?.toDouble() ?? cached.heightCm,
          weightKg: (row['weight_kg'] as num?)?.toDouble() ?? cached.weightKg,
          targetWeightKg:
              (row['target_weight_kg'] as num?)?.toDouble() ??
              cached.targetWeightKg,
          fitnessGoal: row['fitness_goal'] as String? ?? cached.fitnessGoal,
          dietType: row['diet_type'] as String? ?? cached.dietType,
          dailyCaloriesTarget:
              row['daily_calories_target'] as int? ??
              cached.dailyCaloriesTarget,
          targetProteinGrams:
              row['target_protein_grams'] as int? ?? cached.targetProteinGrams,
          targetCarbsGrams:
              row['target_carbs_grams'] as int? ?? cached.targetCarbsGrams,
          targetFatsGrams:
              row['target_fats_grams'] as int? ?? cached.targetFatsGrams,
          targetWaterMl: row['target_water_ml'] as int? ?? cached.targetWaterMl,
          weeklyWorkoutDays:
              row['weekly_workout_days'] as int? ?? cached.weeklyWorkoutDays,
          dailyWorkoutMinutes:
              row['daily_workout_minutes'] as int? ??
              cached.dailyWorkoutMinutes,
          customTargetNote:
              row['custom_target_note'] as String? ?? cached.customTargetNote,
          isProfileSetupCompleted: isSetupDone,
          avatarId: resolvedAvatarId,
          waistCm: (row['waist_cm'] as num?)?.toDouble() ?? cached.waistCm,
          hipCm: (row['hip_cm'] as num?)?.toDouble() ?? cached.hipCm,
          chestCm: (row['chest_cm'] as num?)?.toDouble() ?? cached.chestCm,
          neckCm: (row['neck_cm'] as num?)?.toDouble() ?? cached.neckCm,
          bodyFatPercentage:
              (row['body_fat_percent'] as num?)?.toDouble() ??
              cached.bodyFatPercentage,
          activityLevel:
              row['activity_level'] as String? ?? cached.activityLevel,
          targetSleepHours:
              (row['sleep_hours'] as num?)?.toDouble() ??
              cached.targetSleepHours,
          stressLevel: row['stress_level'] as String? ?? cached.stressLevel,
          reminderFrequencyHours:
              row['reminder_frequency_hours'] as int? ??
              cached.reminderFrequencyHours,
          quietHoursStart:
              row['quiet_hours_start'] as String? ?? cached.quietHoursStart,
          quietHoursEnd:
              row['quiet_hours_end'] as String? ?? cached.quietHoursEnd,
          updatedAt:
              DateTime.tryParse(row['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('[CloudProfileRepository] Remote fetch error: $e');
    }
    return null;
  }

  Future<void> _backgroundRefresh() async {
    try {
      final cached = await _local.loadProfile();
      final updated = await _fetchRemoteProfile(cached);
      if (updated != null) {
        await _local.saveProfile(updated);
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
      return CloudProfileRepository(db: db, userId: user.id, supabase: client);
    }
  }

  return LocalProfileRepository();
});
