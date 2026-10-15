import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final FlutterSecureStorage _storage;
  static const _draftKey = 'fit_host_onboarding_draft';
  static const _completedKey = 'fit_host_onboarding_completed';

  // Memory cache fallback for tests and ultra-fast reads
  OnboardingState? _memoryCache;
  bool _memoryCompleted = false;

  OnboardingRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveDraft(OnboardingState state) async {
    _memoryCache = state;
    try {
      await _storage.write(key: _draftKey, value: state.toJsonString());
    } catch (e) {
      debugPrint('OnboardingRepository: SecureStorage write error (using memory cache): $e');
    }
  }

  @override
  Future<OnboardingState?> loadDraft() async {
    if (_memoryCache != null) return _memoryCache;
    try {
      final jsonStr = await _storage.read(key: _draftKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _memoryCache = OnboardingState.fromJsonString(jsonStr);
        return _memoryCache;
      }
    } catch (e) {
      debugPrint('OnboardingRepository: SecureStorage read error: $e');
    }
    return null;
  }

  @override
  Future<void> clearDraft() async {
    _memoryCache = null;
    try {
      await _storage.delete(key: _draftKey);
    } catch (e) {
      debugPrint('OnboardingRepository: SecureStorage delete error: $e');
    }
  }

  @override
  Future<void> completeOnboarding(OnboardingState state) async {
    _memoryCompleted = true;
    _memoryCache = state.copyWith(isCompleted: true);
    try {
      await _storage.write(key: _completedKey, value: 'true');
      await _storage.write(key: _draftKey, value: _memoryCache!.toJsonString());
    } catch (e) {
      debugPrint('OnboardingRepository: completeOnboarding error: $e');
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    if (_memoryCompleted) return true;
    try {
      final val = await _storage.read(key: _completedKey);
      return val == 'true';
    } catch (e) {
      debugPrint('OnboardingRepository: isOnboardingCompleted error: $e');
      return false;
    }
  }
}
