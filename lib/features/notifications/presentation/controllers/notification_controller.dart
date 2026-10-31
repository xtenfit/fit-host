import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_item.dart';

class NotificationFilterCategoryNotifier
    extends Notifier<NotificationCategory?> {
  @override
  NotificationCategory? build() => null;

  void setCategory(NotificationCategory? cat) => state = cat;
}

final notificationFilterCategoryProvider =
    NotifierProvider<NotificationFilterCategoryNotifier, NotificationCategory?>(
      NotificationFilterCategoryNotifier.new,
    );

class NotificationFilterUnreadOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setUnreadOnly(bool val) => state = val;
}

final notificationFilterUnreadOnlyProvider =
    NotifierProvider<NotificationFilterUnreadOnlyNotifier, bool>(
      NotificationFilterUnreadOnlyNotifier.new,
    );

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id ?? 'guest';
  final repository = ref.watch(notificationRepositoryProvider);

  return repository.watchUnreadCount(userId);
});

final notificationsStreamProvider = StreamProvider<List<NotificationItem>>((
  ref,
) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id ?? 'guest';
  final repository = ref.watch(notificationRepositoryProvider);
  final category = ref.watch(notificationFilterCategoryProvider);
  final unreadOnly = ref.watch(notificationFilterUnreadOnlyProvider);

  return repository.watchInboxNotifications(
    userId,
    category: category,
    unreadOnly: unreadOnly,
  );
});

class NotificationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  String get _currentUserId {
    return ref.read(authProvider).user?.id ?? 'guest';
  }

  NotificationRepository get _repository {
    return ref.read(notificationRepositoryProvider);
  }

  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.markAsRead(id));
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.markAllAsRead(_currentUserId),
    );
  }

  Future<void> deleteNotification(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteNotification(id));
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.clearAll(_currentUserId));
  }

  Future<void> postEventNotification({
    required String title,
    required String body,
    NotificationCategory category = NotificationCategory.general,
    String? actionRoute,
    Map<String, dynamic>? actionPayload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final item = NotificationItem(
        id: '',
        userId: _currentUserId,
        title: title,
        body: body,
        category: category,
        actionRoute: actionRoute,
        actionPayload: actionPayload,
        priority: priority,
        createdAt: DateTime.now(),
      );
      await _repository.insertNotification(item);
    });
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, void>(
      NotificationController.new,
    );
