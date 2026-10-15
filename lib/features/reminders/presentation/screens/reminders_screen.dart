import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
            onPressed: () {
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            controller.completeReminder(rem.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Completed: "${rem.title}"! Keep the streak alive!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
