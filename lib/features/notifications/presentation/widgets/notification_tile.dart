import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../domain/models/notification_item.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.item,
    required this.onMarkRead,
    required this.onDelete,
  });

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.workout:
        return Icons.fitness_center_rounded;
      case NotificationCategory.nutrition:
        return Icons.restaurant_menu_rounded;
      case NotificationCategory.hydration:
        return Icons.water_drop_rounded;
      case NotificationCategory.stepGoal:
        return Icons.directions_walk_rounded;
      case NotificationCategory.reminder:
        return Icons.alarm_rounded;
      case NotificationCategory.system:
        return Icons.shield_outlined;
      case NotificationCategory.general:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.workout:
        return AppColors.electricCyan;
      case NotificationCategory.nutrition:
        return const Color(0xFFFF6B4A);
      case NotificationCategory.hydration:
        return const Color(0xFF00B4D8);
      case NotificationCategory.stepGoal:
        return AppColors.limeGreen;
      case NotificationCategory.reminder:
        return const Color(0xFFFF9E00);
      case NotificationCategory.system:
        return const Color(0xFFA855F7);
      case NotificationCategory.general:
        return Colors.blueGrey;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(item.category);
    final catIcon = _getCategoryIcon(item.category);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: BouncyTap(
        onTap: () {
          if (!item.isRead) {
            onMarkRead();
          }
          if (item.actionRoute != null && item.actionRoute!.isNotEmpty) {
            context.push(item.actionRoute!);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (item.isRead
                      ? AppColors.darkSurface
                      : AppColors.darkSurfaceElevated)
                : (item.isRead ? Colors.white : const Color(0xFFF0FDF4)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !item.isRead
                  ? catColor.withValues(alpha: 0.45)
                  : (isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder),
              width: !item.isRead ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Title, Body, Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimestamp(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? (item.isRead
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFFE2E8F0))
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.actionRoute != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: catColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Unread indicator dot
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
