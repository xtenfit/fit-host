import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/reminder.dart';
import '../controllers/reminders_controller.dart';
import '../widgets/reminder_card.dart';
import '../widgets/add_edit_reminder_dialog.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final remindersAsync = ref.watch(allRemindersProvider);
    final activeRemindersAsync = ref.watch(activeRemindersProvider);
    final selectedCategory = ref.watch(remindersFilterCategoryProvider);
    final controller = ref.read(remindersControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reminders & Alarms',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Alarm & Reminder Sounds',
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () => context.push('/settings/sound-settings'),
          ),
          IconButton(
            onPressed: () async {
              await PermissionService.instance.requestReminderPermissions(context);
              if (!context.mounted) return;
              AddEditReminderDialog.show(
                context,
                onSave: (reminder) => controller.saveReminder(reminder),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.electricBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              if (val == 'test_5_sec') {
                await NotificationService.instance.scheduleAlarm(
                  id: 'test_5_sec_alarm',
                  title: '🔔 Fit Host 5-Sec Test Alarm',
                  body: 'Lockscreen alarm popup is active and ringing!',
                  scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
                  channel: NotificationChannelType.workouts,
                  payload:
                      '/alarm?id=test_5_sec&title=${Uri.encodeComponent('Fit Host Test Alarm')}&body=${Uri.encodeComponent('Your reminder alarm is firing now!')}&channel=workouts&snoozeMinutes=5',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test alarm scheduled in 5s! Lock phone or minimize app now.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (val == 'test_1_min') {
                await PermissionService.instance.requestReminderPermissions(context);
                await NotificationService.instance.testOneMinuteTimer();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test alarm scheduled: firing in 1 minute with ringing popup.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (val == 'permissions') {
                context.push('/permission-settings');
              } else if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Alarms'),
                    content: const Text('Delete all scheduled reminders and alarms?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await controller.clearAllReminders();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All alarms cleared.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'test_5_sec',
                child: Row(
                  children: [
                    Icon(Icons.flash_on_rounded, size: 18, color: AppColors.limeGreen),
                    SizedBox(width: 10),
                    Text('Test 5-Sec Popup Alarm'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_1_min',
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: AppColors.electricBlue),
                    SizedBox(width: 10),
                    Text('Test 1-Min Notification'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'permissions',
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, size: 18, color: Color(0xFF00E676)),
                    SizedBox(width: 10),
                    Text('Permission Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Clear All Alarms', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            // 1. Top Summary Banner
            activeRemindersAsync.when(
              data: (active) {
                final totalActive = active.length;
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF161F38), const Color(0xFF131722)]
                          : [const Color(0xFFEBF3FF), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.electricBlue.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.electricBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalActive Active Fitness Alarms',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalActive > 0
                                  ? 'Next alarm scheduled: ${active.first.formattedTime} (${active.first.title})'
                                  : 'No active alarms. Tap + to set one up.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // 2. Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: selectedCategory == null,
                      label: const Text('All Categories'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selectedCategory == null ? Colors.white : null,
                      ),
                      selectedColor: AppColors.electricBlue,
                      onSelected: (val) {
                        ref.read(remindersFilterCategoryProvider.notifier).setFilter(null);
                      },
                    ),
                  ),
                  ...ReminderCategory.values.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          cat.icon,
                          size: 14,
                          color: isSelected ? Colors.white : cat.color,
                        ),
                        label: Text(cat.label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                        selectedColor: cat.color,
                        onSelected: (val) {
                          ref
                              .read(remindersFilterCategoryProvider.notifier)
                              .setFilter(val ? cat : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Reminders List
            remindersAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.alarm_off_rounded,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Reminders Found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep your workouts, meals, hydration, and sleep on schedule with offline alarms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            AddEditReminderDialog.show(
                              context,
                              onSave: (reminder) => controller.saveReminder(reminder),
                            );
                          },
                          icon: const Icon(Icons.add_alarm_rounded, size: 18),
                          label: const Text('Add Fitness Alarm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final activeItems = list.where((r) => r.isEnabled).toList();
                final inactiveItems = list.where((r) => !r.isEnabled).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeItems.isNotEmpty) ...[
                      const Text(
                        'Active Alarms',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...activeItems.map((rem) {
                        return ReminderCard(
                          reminder: rem,
                          onToggle: (enabled) => controller.toggleReminder(rem.id, enabled),
                          onSnooze: (mins) {
                            controller.snoozeReminder(rem.id, mins);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⏰ Snoozed "${rem.title}" for $mins minutes'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onComplete: () {
                            if (rem.isCompletedToday) {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: isDark ? const Color(0xFF161A22) : Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (ctx) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.limeGreen, size: 48),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Completed for today: ${rem.title}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Today\'s alarm is completed and turned off. The next alert will ring on ${rem.nextOccurrence(DateTime.now()).day == DateTime.now().day + 1 ? 'tomorrow' : 'the next scheduled day'} at ${rem.formattedTime}.',
                                          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  controller.uncompleteReminder(rem.id);
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Marked "${rem.title}" as pending for today.'),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                },
                                                child: const Text('Mark as Pending'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.limeGreen,
                                                  foregroundColor: Colors.black,
                                                ),
                                                child: const Text('Keep Completed'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              controller.completeReminder(rem.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 Completed for today: "${rem.title}"! Next alarm is scheduled for tomorrow.'),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    textColor: AppColors.limeGreen,
                                    onPressed: () => controller.uncompleteReminder(rem.id),
                                  ),
                                ),
                              );
                            }
                          },
                          onDismiss: () => controller.dismissReminder(rem.id),
                          onEdit: () {
                            AddEditReminderDialog.show(
                              context,
                              initialReminder: rem,
                              onSave: (updated) => controller.updateReminder(updated),
                            );
                          },
                          onDelete: () => controller.deleteReminder(rem.id),
                        );
                      }),
                    ],
                    if (inactiveItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Inactive / Paused',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...inactiveItems.map((rem) {
                        return ReminderCard(
                          reminder: rem,
                          onToggle: (enabled) => controller.toggleReminder(rem.id, enabled),
                          onSnooze: (_) {},
                          onComplete: () {},
                          onDismiss: () {},
                          onEdit: () {
                            AddEditReminderDialog.show(
                              context,
                              initialReminder: rem,
                              onSave: (updated) => controller.updateReminder(updated),
                            );
                          },
                          onDelete: () => controller.deleteReminder(rem.id),
                        );
                      }),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $err'),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
