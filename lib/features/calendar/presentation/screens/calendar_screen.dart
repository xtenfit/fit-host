import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/calendar_range_controller.dart';
import '../widgets/month_view_grid.dart';
import '../widgets/week_view_strip.dart';
import '../widgets/day_view_timeline.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/add_edit_event_dialog.dart';
import '../widgets/range_aggregation_card.dart';
import '../../../auth/presentation/dialogs/feature_upsell_sheet.dart';
import '../../../../core/services/supabase_service.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final calendarState = ref.watch(calendarStateProvider);
    final calendarNotifier = ref.read(calendarStateProvider.notifier);

    final selectedDateEventsAsync = ref.watch(calendarEventsForSelectedDateProvider);
    final monthEventsAsync = ref.watch(calendarEventsForMonthProvider);
    final allEventsAsync = ref.watch(allCalendarEventsProvider);
    final monthSummariesAsync = ref.watch(monthSummariesMapProvider(calendarState.focusedMonth));
    final daySummaries = monthSummariesAsync.value ?? {};

    final formattedPeriod = calendarState.viewMode == CalendarViewMode.day
        ? DateFormat('EEEE, MMM d, yyyy').format(calendarState.selectedDate)
        : DateFormat('MMMM yyyy').format(calendarState.focusedMonth);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fitness Calendar',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          // "Today" shortcut button
          TextButton.icon(
            onPressed: () {
              calendarNotifier.jumpToToday();
              ref.read(calendarRangeProvider.notifier).setFocusedDate(DateTime.now());
            },
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.electricBlue,
            ),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Events'),
                    content: const Text('Delete all scheduled activities and events from your calendar?'),
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
                  await calendarNotifier.clearAllEvents();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All calendar events cleared.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Clear All Events', style: TextStyle(color: Colors.redAccent)),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // 0. Range Aggregation Panel (Today / Week / Month / Custom)
            const RangeAggregationCard(),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // 1. Period Navigator Row (< Month/Year > & View Switcher)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => calendarNotifier.previousPeriod(),
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                ),
                Text(
                  formattedPeriod,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                IconButton(
                  onPressed: () => calendarNotifier.nextPeriod(),
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. View Mode Segmented Control (Month / Week / Day)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: CalendarViewMode.values.map((mode) {
                  final auth = ref.watch(authProvider);
                  final isSelected = calendarState.viewMode == mode;
                  final isLocked = mode == CalendarViewMode.month && auth.isGuest;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isLocked) {
                          FeatureUpsellSheet.show(
                            context,
                            title: 'Month Calendar View',
                            description:
                                'Track your entire month of workouts, nutrition logs, and streaks in one unified grid with a free Fit Host account.',
                            icon: Icons.calendar_month_rounded,
                          );
                          return;
                        }
                        calendarNotifier.setViewMode(mode);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF232733) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.electricBlue
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                              ),
                              if (isLocked) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.lock_rounded, size: 11, color: Colors.amber),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: calendarState.selectedCategoryFilter == null,
                      label: const Text('All Activities'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: calendarState.selectedCategoryFilter == null
                            ? Colors.white
                            : null,
                      ),
                      selectedColor: AppColors.electricBlue,
                      onSelected: (val) {
                        calendarNotifier.setCategoryFilter(null);
                      },
                    ),
                  ),
                  ...CalendarEventType.values.map((type) {
                    final isSelected = calendarState.selectedCategoryFilter == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          type.icon,
                          size: 14,
                          color: isSelected ? Colors.white : type.color,
                        ),
                        label: Text(type.label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                        selectedColor: type.color,
                        onSelected: (val) {
                          calendarNotifier.setCategoryFilter(val ? type : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. View Mode Widget (Month, Week, or Day)
            if (calendarState.viewMode == CalendarViewMode.month)
              monthEventsAsync.when(
                data: (events) => MonthViewGrid(
                  focusedMonth: calendarState.focusedMonth,
                  selectedDate: calendarState.selectedDate,
                  monthEvents: events,
                  daySummaries: daySummaries,
                  onSelectDate: (date) {
                    calendarNotifier.selectDate(date);
                    ref.read(calendarRangeProvider.notifier).setFocusedDate(date);
                  },
                  onSwipeLeft: () => calendarNotifier.nextPeriod(),
                  onSwipeRight: () => calendarNotifier.previousPeriod(),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error loading month: $err')),
              )
            else if (calendarState.viewMode == CalendarViewMode.week)
              allEventsAsync.when(
                data: (events) => WeekViewStrip(
                  selectedDate: calendarState.selectedDate,
                  allEvents: events,
                  daySummaries: daySummaries,
                  onSelectDate: (date) {
                    calendarNotifier.selectDate(date);
                    ref.read(calendarRangeProvider.notifier).setFocusedDate(date);
                  },
                  onSwipeLeft: () => calendarNotifier.nextPeriod(),
                  onSwipeRight: () => calendarNotifier.previousPeriod(),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
              )
            else
              selectedDateEventsAsync.when(
                data: (events) => DayViewTimeline(
                  selectedDate: calendarState.selectedDate,
                  dayEvents: events,
                  onToggleComplete: (e) =>
                      calendarNotifier.toggleCompletion(e.id, !e.isCompleted),
                  onReschedule: (e, newDate, newTime) =>
                      calendarNotifier.rescheduleEvent(e.id, newDate, newTime),
                  onEdit: (e) => AddEditEventDialog.show(
                    context,
                    initialEvent: e,
                    selectedDate: calendarState.selectedDate,
                    onSave: (updated) => calendarNotifier.updateEvent(updated),
                  ),
                  onDelete: (e) => calendarNotifier.deleteEvent(e.id),
                  onAddAtSlot: (slotTime) {
                    AddEditEventDialog.show(
                      context,
                      selectedDate: calendarState.selectedDate,
                      onSave: (event) => calendarNotifier.addEvent(
                        event.copyWith(startTime: slotTime),
                      ),
                    );
                  },
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),

            // If in Month or Week mode, show the daily agenda below
            if (calendarState.viewMode != CalendarViewMode.day) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agenda • ${DateFormat('EEEE, MMM d').format(calendarState.selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      AddEditEventDialog.show(
                        context,
                        selectedDate: calendarState.selectedDate,
                        onSave: (event) => calendarNotifier.addEvent(event),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    color: AppColors.electricBlue,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              selectedDateEventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 44,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No activities scheduled for this date',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Plan a workout, log a recovery rest day, or set meal targets',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              AddEditEventDialog.show(
                                context,
                                selectedDate: calendarState.selectedDate,
                                onSave: (event) => calendarNotifier.addEvent(event),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Activity'),
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
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading events: $err'),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
