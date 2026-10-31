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
  final String? userId;

  static const _legacyProfileKey = 'fit_host_user_profile';

  String get _effectiveKey =>
      (userId != null && userId!.isNotEmpty && userId != 'guest')
      ? 'fit_host_user_profile_$userId'
      : 'fit_host_user_profile_guest';

  // Memory cache fallback scoped by storage key
  static final Map<String, UserProfile> _memoryCaches = {};

  UserProfileRepositoryImpl({FlutterSecureStorage? storage, this.userId})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<UserProfile> loadProfile() async {
    final key = _effectiveKey;
    if (_memoryCaches.containsKey(key)) return _memoryCaches[key]!;

    try {
      var jsonStr = await _storage.read(key: key);
      if (jsonStr == null || jsonStr.isEmpty) {
        // Fallback migration from legacy unscoped key
        final legacyStr = await _storage.read(key: _legacyProfileKey);
        if (legacyStr != null && legacyStr.isNotEmpty) {
          jsonStr = legacyStr;
          // Migrate to scoped key
          await _storage.write(key: key, value: legacyStr);
        }
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final loaded = UserProfile.fromJsonString(jsonStr);
        _memoryCaches[key] = loaded;
        return loaded;
      }
    } catch (e) {
      debugPrint(
        'UserProfileRepository: storage read error (falling back to default): $e',
      );
    }

    // Default suggested profile for athlete
    final isGuest = userId == null || userId!.isEmpty || userId == 'guest';
    final defaultProfile = UserProfile.calculateSuggestedTargets(
      id: userId ?? 'guest',
      name: isGuest ? 'Guest Athlete' : 'Athlete',
      age: 0,
      gender: 'male',
      heightCm: 0.0,
      weightKg: 0.0,
      targetWeightKg: null,
      fitnessGoal: 'maintain_weight',
      dietType: 'balanced',
      weeklyWorkoutDays: 4,
      dailyWorkoutMinutes: 45,
      isCompleted: false,
    );
    _memoryCaches[key] = defaultProfile;
    return defaultProfile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final key = _effectiveKey;
    _memoryCaches[key] = profile;
    try {
      await _storage.write(key: key, value: profile.toJsonString());
    } catch (e) {
      debugPrint(
        'UserProfileRepository: storage write error (cached in memory): $e',
      );
    }
  }

  @override
  Future<void> resetProfile() async {
    final key = _effectiveKey;
    _memoryCaches.remove(key);
    try {
      await _storage.delete(key: key);
      if (key == 'fit_host_user_profile_guest') {
        await _storage.delete(key: _legacyProfileKey);
      }
    } catch (e) {
      debugPrint('UserProfileRepository: storage delete error: $e');
    }
  }
}
