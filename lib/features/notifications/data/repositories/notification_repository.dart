import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/notification_item.dart';

abstract class NotificationRepository {
  Stream<List<NotificationItem>> watchInboxNotifications(
    String userId, {
    NotificationCategory? category,
    bool unreadOnly = false,
  });

  Stream<int> watchUnreadCount(String userId);

  Future<void> insertNotification(NotificationItem item);

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead(String userId);

  Future<void> archiveNotification(String id);

  Future<void> deleteNotification(String id);

  Future<void> clearAll(String userId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  NotificationRepositoryImpl(this._db, [Uuid? uuid])
    : _uuid = uuid ?? const Uuid();

  @override
  Stream<List<NotificationItem>> watchInboxNotifications(
    String userId, {
    NotificationCategory? category,
    bool unreadOnly = false,
  }) {
    final query = _db.select(_db.notificationInboxItems)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));

    if (category != null) {
      query.where((t) => t.category.equals(category.dbValue));
    }

    if (unreadOnly) {
      query.where((t) => t.isRead.equals(false));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    final countExpr = _db.notificationInboxItems.id.count();
    final query = _db.selectOnly(_db.notificationInboxItems)
      ..addColumns([countExpr])
      ..where(
        _db.notificationInboxItems.userId.equals(userId) &
            _db.notificationInboxItems.isDeleted.equals(false) &
            _db.notificationInboxItems.isRead.equals(false),
      );

    return query.watchSingle().map((row) => row.read(countExpr) ?? 0);
  }

  @override
  Future<void> insertNotification(NotificationItem item) async {
    final companion = NotificationInboxItemsCompanion.insert(
      id: item.id.isNotEmpty ? item.id : _uuid.v4(),
      userId: Value(item.userId),
      title: item.title,
      body: item.body,
      category: Value(item.category.dbValue),
      actionRoute: Value(item.actionRoute),
      actionPayload: Value(
        item.actionPayload != null ? jsonEncode(item.actionPayload) : null,
      ),
      isRead: Value(item.isRead),
      isArchived: Value(item.isArchived),
      priority: Value(item.priority.dbValue),
      createdAt: Value(item.createdAt),
      readAt: Value(item.readAt),
      isDeleted: const Value(false),
      syncStatus: const Value('pending'),
    );

    await _db
        .into(_db.notificationInboxItems)
        .insert(companion, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> markAsRead(String id) async {
    await (_db.update(
      _db.notificationInboxItems,
    )..where((t) => t.id.equals(id))).write(
      NotificationInboxItemsCompanion(
        isRead: const Value(true),
        readAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await (_db.update(
      _db.notificationInboxItems,
    )..where((t) => t.userId.equals(userId) & t.isRead.equals(false))).write(
      NotificationInboxItemsCompanion(
        isRead: const Value(true),
        readAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> archiveNotification(String id) async {
    await (_db.update(_db.notificationInboxItems)
          ..where((t) => t.id.equals(id)))
        .write(const NotificationInboxItemsCompanion(isArchived: Value(true)));
  }

  @override
  Future<void> deleteNotification(String id) async {
    await (_db.update(
      _db.notificationInboxItems,
    )..where((t) => t.id.equals(id))).write(
      NotificationInboxItemsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> clearAll(String userId) async {
    await (_db.update(
      _db.notificationInboxItems,
    )..where((t) => t.userId.equals(userId))).write(
      NotificationInboxItemsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  NotificationItem _mapToDomain(NotificationInboxData row) {
    Map<String, dynamic>? payload;
    if (row.actionPayload != null) {
      try {
        payload = jsonDecode(row.actionPayload!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return NotificationItem(
      id: row.id,
      userId: row.userId,
      title: row.title,
      body: row.body,
      category: NotificationCategory.fromString(row.category),
      actionRoute: row.actionRoute,
      actionPayload: payload,
      isRead: row.isRead,
      isArchived: row.isArchived,
      priority: NotificationPriority.fromString(row.priority),
      createdAt: row.createdAt,
      readAt: row.readAt,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationRepositoryImpl(db);
});
