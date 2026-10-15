import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/reminder.dart';
import '../../data/repositories/reminder_repository.dart';

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

  Future<void> completeReminder(String id) => _repo.completeReminder(id);

  Future<void> dismissReminder(String id) => _repo.dismissReminder(id);

  Future<void> deleteReminder(String id) => _repo.deleteReminder(id);

  Future<void> saveReminder(Reminder reminder) async {
    if (reminder.id.isEmpty) {
      await _repo.createReminder(reminder);
    } else {
      await _repo.createReminder(reminder);
    }
  }

  Future<void> updateReminder(Reminder reminder) =>
      _repo.updateReminder(reminder);
}

final remindersControllerProvider = Provider<RemindersController>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return RemindersController(repo);
});
