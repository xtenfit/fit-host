import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../calendar/presentation/controllers/calendar_controller.dart';
import '../../calendar/presentation/widgets/add_edit_event_dialog.dart';
import '../../calendar/presentation/widgets/calendar_event_card.dart';

class DailyPlannerScreen extends ConsumerWidget {
  const DailyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final calendarState = ref.watch(calendarStateProvider);
    final calendarNotifier = ref.read(calendarStateProvider.notifier);
    final eventsAsync = ref.watch(calendarEventsForSelectedDateProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = calendarState.selectedDate.year == today.year &&
        calendarState.selectedDate.month == today.month &&
        calendarState.selectedDate.day == today.day;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Daily Planner',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/calendar'),
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'View Full Calendar',
          ),
          IconButton(
            onPressed: () {
              AddEditEventDialog.show(
                context,
                selectedDate: calendarState.selectedDate,
                onSave: (event) => calendarNotifier.addEvent(event),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            // Date Switcher Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final prev = calendarState.selectedDate.subtract(const Duration(days: 1));
                      calendarNotifier.selectDate(prev);
                    },
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isToday ? 'Today' : DateFormat('EEEE').format(calendarState.selectedDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.electricBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy').format(calendarState.selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final next = calendarState.selectedDate.add(const Duration(days: 1));
                      calendarNotifier.selectDate(next);
                    },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress Summary Card
            eventsAsync.when(
              data: (events) {
                final total = events.length;
                final completed = events.where((e) => e.isCompleted).length;
                final pct = total > 0 ? (completed / total) : 0.0;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF161F38), const Color(0xFF131722)]
                          : [const Color(0xFFEBF3FF), Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.electricBlue.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 6,
                              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.limeGreen),
                            ),
                          ),
                          Text(
                            '${(pct * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completed of $total Activities Done',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              completed == total && total > 0
                                  ? '🎉 Outstanding! All scheduled tasks completed!'
                                  : 'Follow your plan to keep your streak and fitness goals on track.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
            const SizedBox(height: 20),

            // Daily Tasks List
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
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
                          Icons.checklist_rounded,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Tasks Planned For Today',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add a workout, meal timing, or water check-in to structure your day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            AddEditEventDialog.show(
                              context,
                              selectedDate: calendarState.selectedDate,
                              onSave: (event) => calendarNotifier.addEvent(event),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Daily Task'),
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

                return Column(
                  children: events.map((event) {
                    return CalendarEventCard(
                      event: event,
                      onToggleComplete: () =>
                          calendarNotifier.toggleCompletion(event.id, !event.isCompleted),
                      onReschedule: (newDate, newTime) =>
                          calendarNotifier.rescheduleEvent(event.id, newDate, newTime),
                      onEdit: () => AddEditEventDialog.show(
                        context,
                        initialEvent: event,
                        selectedDate: calendarState.selectedDate,
                        onSave: (updated) => calendarNotifier.updateEvent(updated),
                      ),
                      onDelete: () => calendarNotifier.deleteEvent(event.id),
                    );
                  }).toList(),
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
