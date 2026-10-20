import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> loadProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> resetProfile();
}

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FlutterSecureStorage _storage;
  static const _profileKey = 'fit_host_user_profile';

  // Memory cache fallback for tests and instant reads
  static UserProfile? _memoryCache;

  UserProfileRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<UserProfile> loadProfile() async {
    if (_memoryCache != null) return _memoryCache!;
    try {
      final jsonStr = await _storage.read(key: _profileKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _memoryCache = UserProfile.fromJsonString(jsonStr);
        return _memoryCache!;
      }
    } catch (e) {
      debugPrint('UserProfileRepository: storage read error (falling back to default): $e');
    }

    // Default suggested profile for Guest Athlete
    final defaultProfile = UserProfile.calculateSuggestedTargets(
      name: 'Guest Athlete',
      age: 26,
      gender: 'male',
      heightCm: 175.0,
      weightKg: 72.0,
      targetWeightKg: 70.0,
      fitnessGoal: 'maintain_weight',
      dietType: 'balanced',
      weeklyWorkoutDays: 4,
      dailyWorkoutMinutes: 45,
      isCompleted: true,
    );
    _memoryCache = defaultProfile;
    return defaultProfile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _memoryCache = profile;
    try {
      await _storage.write(key: _profileKey, value: profile.toJsonString());
    } catch (e) {
      debugPrint('UserProfileRepository: storage write error (cached in memory): $e');
    }
  }

  @override
  Future<void> resetProfile() async {
    _memoryCache = null;
    try {
      await _storage.delete(key: _profileKey);
    } catch (e) {
      debugPrint('UserProfileRepository: storage delete error: $e');
    }
  }
}
