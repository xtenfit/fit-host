import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/reminder.dart';

class AddEditReminderDialog extends StatefulWidget {
  final Reminder? initialReminder;
  final Function(Reminder) onSave;

  const AddEditReminderDialog({
    super.key,
    this.initialReminder,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Reminder? initialReminder,
    required Function(Reminder) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditReminderDialog(
        initialReminder: initialReminder,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditReminderDialog> createState() => _AddEditReminderDialogState();
}

class _AddEditReminderDialogState extends State<AddEditReminderDialog> {
  late TextEditingController _titleController;
  late ReminderCategory _category;
  late TimeOfDay _timeOfDay;
  late ReminderRecurrence _recurrence;
  late List<int> _repeatDays;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late int _snoozeMinutes;

  @override
  void initState() {
    super.initState();
    final rem = widget.initialReminder;
    _titleController = TextEditingController(text: rem?.title ?? '');
    _category = rem?.category ?? ReminderCategory.workout;

    if (rem != null) {
      _timeOfDay = TimeOfDay(hour: rem.hour, minute: rem.minute);
    } else {
      _timeOfDay = const TimeOfDay(hour: 8, minute: 0);
    }

    _recurrence = rem?.recurrence ?? ReminderRecurrence.daily;
    _repeatDays = List.from(rem?.repeatDays ?? [1, 2, 3, 4, 5]);
    _soundEnabled = rem?.soundEnabled ?? true;
    _vibrationEnabled = rem?.vibrationEnabled ?? true;
    _snoozeMinutes = rem?.snoozeDurationMinutes ?? 10;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialReminder != null;

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Reminder' : 'Set Smart Reminder',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Chips
            const Text(
              'Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReminderCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 15,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          const SizedBox(width: 6),
                          Text(cat.label),
                        ],
                      ),
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _category = cat;
                          if (_titleController.text.isEmpty) {
                            switch (cat) {
                              case ReminderCategory.workout:
                                _titleController.text = 'Workout Session';
                                break;
                              case ReminderCategory.meal:
                                _titleController.text = 'Healthy Meal Fuel';
                                break;
                              case ReminderCategory.hydration:
                                _titleController.text = 'Drink Water (500ml)';
                                break;
                              case ReminderCategory.sleep:
                                _titleController.text = 'Bedtime Wind-Down';
                                break;
                              case ReminderCategory.habit:
                                _titleController.text = 'Daily Habit Check';
                                break;
                              case ReminderCategory.custom:
                                _titleController.text = 'Custom Fitness Alarm';
                                break;
                            }
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Reminder Label *',
                hintText: 'e.g. Morning Hydration, Pre-Workout Meal',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Selector Card
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _timeOfDay,
                );
                if (picked != null) {
                  setState(() => _timeOfDay = picked);
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alarm_rounded, color: AppColors.electricBlue),
                        const SizedBox(width: 12),
                        const Text(
                          'Alarm Time',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      _timeOfDay.format(context),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.electricBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recurrence Dropdown
            DropdownButtonFormField<ReminderRecurrence>(
              initialValue: _recurrence,
              decoration: InputDecoration(
                labelText: 'Schedule / Repeat',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: ReminderRecurrence.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _recurrence = val);
              },
            ),

            // If Custom days selected, show 7-day checkboxes
            if (_recurrence == ReminderRecurrence.custom) ...[
              const SizedBox(height: 12),
              const Text(
                'Repeat on Days:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayIndex = i + 1; // 1 = Monday
                  final isSelected = _repeatDays.contains(dayIndex);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _repeatDays.remove(dayIndex);
                        } else {
                          _repeatDays.add(dayIndex);
                          _repeatDays.sort();
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.electricBlue
                            : (isDark ? AppColors.darkSurfaceElevated : Colors.grey[200]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),

            // Snooze & Sound Settings
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  // Sound Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volume_up_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Sound Alert', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Switch.adaptive(
                        value: _soundEnabled,
                        activeTrackColor: AppColors.electricBlue,
                        onChanged: (val) => setState(() => _soundEnabled = val),
                      ),
                    ],
                  ),
                  const Divider(height: 1),

                  // Vibration Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.vibration_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Vibration', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Switch.adaptive(
                        value: _vibrationEnabled,
                        activeTrackColor: AppColors.electricBlue,
                        onChanged: (val) => setState(() => _vibrationEnabled = val),
                      ),
                    ],
                  ),
                  const Divider(height: 1),

                  // Snooze Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.snooze_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Snooze Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      DropdownButton<int>(
                        value: _snoozeMinutes,
                        underline: const SizedBox.shrink(),
                        items: [5, 10, 15, 30, 60].map((mins) {
                          return DropdownMenuItem(
                            value: mins,
                            child: Text('$mins mins'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _snoozeMinutes = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a reminder label')),
                    );
                    return;
                  }

                  final hStr = _timeOfDay.hour.toString().padLeft(2, '0');
                  final mStr = _timeOfDay.minute.toString().padLeft(2, '0');
                  final timeStr = '$hStr:$mStr';

                  final now = DateTime.now();
                  final reminder = Reminder(
                    id: widget.initialReminder?.id ?? const Uuid().v4(),
                    title: title,
                    category: _category,
                    timeOfDay: timeStr,
                    isEnabled: widget.initialReminder?.isEnabled ?? true,
                    recurrence: _recurrence,
                    repeatDays: _repeatDays,
                    soundEnabled: _soundEnabled,
                    vibrationEnabled: _vibrationEnabled,
                    snoozeDurationMinutes: _snoozeMinutes,
                    lastTriggeredAt: widget.initialReminder?.lastTriggeredAt,
                    lastCompletedAt: widget.initialReminder?.lastCompletedAt,
                    isDismissed: widget.initialReminder?.isDismissed ?? false,
                    createdAt: widget.initialReminder?.createdAt ?? now,
                    updatedAt: now,
                  );

                  widget.onSave(reminder);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isEditing ? 'Save Reminder' : 'Set Reminder',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
