import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_event.dart';

class AddEditEventDialog extends StatefulWidget {
  final CalendarEvent? initialEvent;
  final DateTime selectedDate;
  final Function(CalendarEvent) onSave;

  const AddEditEventDialog({
    super.key,
    this.initialEvent,
    required this.selectedDate,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    CalendarEvent? initialEvent,
    required DateTime selectedDate,
    required Function(CalendarEvent) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditEventDialog(
        initialEvent: initialEvent,
        selectedDate: selectedDate,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _metricController;
  late CalendarEventType _eventType;
  late RecurrenceRule _recurrenceRule;
  late DateTime _scheduledDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _eventType = event?.eventType ?? CalendarEventType.workout;
    _recurrenceRule = event?.recurrenceRule ?? RecurrenceRule.none;
    _scheduledDate = event?.scheduledDate ?? widget.selectedDate;

    if (event?.startTime != null) {
      _startTime = TimeOfDay(hour: event!.startTime!.hour, minute: event.startTime!.minute);
    } else {
      _startTime = const TimeOfDay(hour: 17, minute: 30);
    }

    if (event?.endTime != null) {
      _endTime = TimeOfDay(hour: event!.endTime!.hour, minute: event.endTime!.minute);
    } else {
      _endTime = const TimeOfDay(hour: 18, minute: 30);
    }

    String initialMetric = '';
    if (event?.targetMetrics != null && event!.targetMetrics!.isNotEmpty) {
      final firstVal = event.targetMetrics!.values.first;
      initialMetric = firstVal.toString();
    }
    _metricController = TextEditingController(text: initialMetric);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _metricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialEvent != null;

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
                  isEditing ? 'Edit Activity' : 'Schedule Activity',
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

            // Event Type Chips
            const Text(
              'Activity Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CalendarEventType.values.map((type) {
                  final isSelected = _eventType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 15,
                            color: isSelected ? Colors.white : type.color,
                          ),
                          const SizedBox(width: 6),
                          Text(type.label),
                        ],
                      ),
                      selectedColor: type.color,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null,
                      ),
                      onSelected: (val) {
                        setState(() => _eventType = type);
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
                labelText: 'Activity Title *',
                hintText: 'e.g. Chest & Triceps, Post-Workout Protein, 3L Water',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description / Notes',
                hintText: 'Add workout targets, nutrition macros, or hydration goals',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Date Picker Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _scheduledDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _scheduledDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, MMM d').format(_scheduledDate),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Start Time
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => _startTime = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _startTime != null ? _startTime!.format(context) : 'Set Time',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Recurrence Row
            Row(
              children: [
                const Text(
                  'Repeat:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<RecurrenceRule>(
                    initialValue: _recurrenceRule,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: RecurrenceRule.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r.label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _recurrenceRule = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Target Metric Input
            TextField(
              controller: _metricController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Metric (e.g. Calories, Minutes, Milliliters, Kg)',
                hintText: 'e.g. 500',
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an activity title')),
                    );
                    return;
                  }

                  DateTime? start;
                  if (_startTime != null) {
                    start = DateTime(
                      _scheduledDate.year,
                      _scheduledDate.month,
                      _scheduledDate.day,
                      _startTime!.hour,
                      _startTime!.minute,
                    );
                  }

                  DateTime? end;
                  if (_endTime != null) {
                    end = DateTime(
                      _scheduledDate.year,
                      _scheduledDate.month,
                      _scheduledDate.day,
                      _endTime!.hour,
                      _endTime!.minute,
                    );
                  }

                  Map<String, dynamic>? metrics;
                  final metricNum = num.tryParse(_metricController.text.trim());
                  if (metricNum != null) {
                    metrics = {'value': metricNum};
                  }

                  final now = DateTime.now();
                  final event = CalendarEvent(
                    id: widget.initialEvent?.id ?? const Uuid().v4(),
                    title: title,
                    description: _descriptionController.text.trim().isEmpty
                        ? null
                        : _descriptionController.text.trim(),
                    eventType: _eventType,
                    scheduledDate: _scheduledDate,
                    startTime: start,
                    endTime: end,
                    isCompleted: widget.initialEvent?.isCompleted ?? false,
                    isMissed: widget.initialEvent?.isMissed ?? false,
                    recurrenceRule: _recurrenceRule,
                    targetMetrics: metrics,
                    createdAt: widget.initialEvent?.createdAt ?? now,
                    updatedAt: now,
                  );

                  widget.onSave(event);
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
                  isEditing ? 'Save Changes' : 'Schedule Activity',
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
