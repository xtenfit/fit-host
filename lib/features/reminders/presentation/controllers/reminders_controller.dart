import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import 'package:fit_host/core/services/analytics_service.dart';

class RemindersFilterNotifier extends Notifier<ReminderCategory?> {
  @override
  ReminderCategory? build() => null;

  void setFilter(ReminderCategory? cat) => state = cat;
}

final remindersFilterCategoryProvider =
    NotifierProvider<RemindersFilterNotifier, ReminderCategory?>(
      RemindersFilterNotifier.new,
    );

final allRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final filter = ref.watch(remindersFilterCategoryProvider);

  return repo.watchAllReminders().map((list) {
    if (filter == null) return list;
    return list.where((r) => r.category == filter).toList();
  });
});

final activeRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.watchActiveReminders();
});

class RemindersController {
  final ReminderRepository _repo;

  RemindersController(this._repo);

  Future<void> toggleReminder(String id, bool isEnabled) =>
      _repo.toggleEnabled(id, isEnabled);

  Future<void> snoozeReminder(String id, int minutes) =>
      _repo.snoozeReminder(id, minutes);

  Future<void> completeReminder(String id) async {
    await _repo.completeReminder(id);
    AnalyticsService.instance.track(AnalyticsEvents.reminderCompleted).ignore();
  }

  Future<void> uncompleteReminder(String id) => _repo.uncompleteReminder(id);

  Future<void> dismissReminder(String id) => _repo.dismissReminder(id);

  Future<void> deleteReminder(String id) => _repo.deleteReminder(id);

  Future<void> saveReminder(Reminder reminder) async {
    final existing = reminder.id.isEmpty
        ? null
        : await _repo.getReminder(reminder.id);
    if (existing == null) {
      await _repo.createReminder(reminder);
      AnalyticsService.instance
          .track(
            AnalyticsEvents.reminderCreated,
            properties: {'is_enabled': reminder.isEnabled},
          )
          .ignore();
    } else {
      await _repo.updateReminder(reminder);
    }
  }

  Future<void> updateReminder(Reminder reminder) =>
      _repo.updateReminder(reminder);

  Future<void> cleanDemoReminders() => _repo.cleanDemoSeededReminders();

  Future<void> clearAllReminders() => _repo.clearAllReminders();
}

final remindersControllerProvider = Provider<RemindersController>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return RemindersController(repo);
});
