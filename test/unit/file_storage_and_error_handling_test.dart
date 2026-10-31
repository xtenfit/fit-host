import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/services/supabase_service.dart';
import 'package:fit_host/core/services/supabase_storage_service.dart';
import 'package:fit_host/core/sync/sync_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('File Storage & Bucket Configuration Tests', () {
    test('StorageBuckets defines canonical bucket IDs', () {
      expect(StorageBuckets.avatars, equals('avatars'));
      expect(StorageBuckets.progressPhotos, equals('progress-photos'));
      expect(StorageBuckets.diaryAttachments, equals('diary-attachments'));
      expect(StorageBuckets.workoutAttachments, equals('workout-attachments'));
    });

    test('SupabaseFileStorageService generates structured user paths', () {
      final service = SupabaseFileStorageService(null);

      final avatarPath = service.generateStoragePath(
        bucket: StorageBuckets.avatars,
        userId: 'user-uuid-123',
        fileName: 'avatar.png',
      );
      expect(avatarPath, equals('user-uuid-123/avatar.png'));

      final photoPath = service.generateStoragePath(
        bucket: StorageBuckets.progressPhotos,
        userId: 'user-uuid-456',
        fileName: 'front_double_biceps.webp',
      );
      expect(photoPath, equals('user-uuid-456/front_double_biceps.webp'));
    });
  });

  group('Auth Error Formatting & Supabase Recovery Parsing Tests', () {
    test(
      'formatAuthError decodes JSON recovery email failure into friendly message',
      () {
        const jsonError =
            '{"code":"unexpected_failure","message":"Error sending recovery email"}';
        final formatted = formatAuthError(jsonError);

        expect(formatted, contains('Unable to send recovery email'));
        expect(formatted, contains('OTP code'));
      },
    );

    test('formatAuthError decodes JSON rate limit error', () {
      const jsonError =
          '{"code":"over_email_send_rate_limit","message":"Rate limit exceeded for email"}';
      final formatted = formatAuthError(jsonError);

      expect(formatted, contains('Email rate limit exceeded'));
    });

    test('formatAuthError preserves plain error messages', () {
      const plain = 'Custom backend service unavailable';
      final formatted = formatAuthError(plain);

      expect(formatted, equals('Custom backend service unavailable'));
    });
  });

  group('Reminders Local-First Sync Architecture Tests', () {
    test(
      'sanitizeOutboxPayload strips local alarm engine fields for reminder_schedules',
      () {
        final rawReminder = {
          'id': 'rem_12345',
          'user_id': 'user_abc',
          'category': 'water',
          'time_of_day': '08:30',
          'repeat_days': '1,2,3,4,5',
          'is_enabled': true,
          'sound_enabled': true,
          'vibration_enabled': true,
          'snooze_duration_minutes': 10,
          'last_triggered_at': '2026-10-26T08:30:00Z',
          'delivery_mode': 'alarm',
          'updated_at': '2026-10-26T08:30:00Z',
        };

        final sanitized = sanitizeOutboxPayload(
          'reminder_schedules',
          rawReminder,
          'user_abc',
        );

        // Verify schedule fields are preserved
        expect(sanitized['id'], equals('rem_12345'));
        expect(sanitized['category'], equals('water'));
        expect(sanitized['time_of_day'], equals('08:30'));
        expect(sanitized['repeat_days'], equals('1,2,3,4,5'));
        expect(sanitized['is_enabled'], equals(true));

        // Verify local alarm engine fields are completely stripped from cloud payload
        expect(sanitized.containsKey('sound_enabled'), isFalse);
        expect(sanitized.containsKey('vibration_enabled'), isFalse);
        expect(sanitized.containsKey('snooze_duration_minutes'), isFalse);
        expect(sanitized.containsKey('last_triggered_at'), isFalse);
        expect(sanitized.containsKey('delivery_mode'), isFalse);
      },
    );

    test(
      'sanitizeOutboxPayload maps step_count to steps for step_daily_logs',
      () {
        final rawSteps = {
          'id': 'step_123',
          'user_id': 'user_abc',
          'step_date': '2026-10-26',
          'step_count': 8540,
          'target_step_count': 10000,
          'distance_meters': 6200.5,
          'active_calories': 340,
        };

        final sanitized = sanitizeOutboxPayload(
          'step_daily_logs',
          rawSteps,
          'user_abc',
        );

        expect(sanitized['steps'], equals(8540));
        expect(sanitized['target_steps'], equals(10000));
        expect(sanitized.containsKey('step_count'), isFalse);
        expect(sanitized.containsKey('target_step_count'), isFalse);
      },
    );
  });
}
