import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryTodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final String dateKey;
  final bool isCustom;

  const DiaryTodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.dateKey,
    this.isCustom = false,
  });

  DiaryTodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    String? dateKey,
    bool? isCustom,
  }) {
    return DiaryTodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dateKey: dateKey ?? this.dateKey,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'dateKey': dateKey,
        'isCustom': isCustom,
      };

  factory DiaryTodoItem.fromJson(Map<String, dynamic> json) => DiaryTodoItem(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        dateKey: json['dateKey'] as String,
        isCustom: json['isCustom'] as bool? ?? false,
      );
}

class DiaryTodoService {
  static const _kPrefix = 'fit_host_diary_todos_';

  static List<DiaryTodoItem> getStandardDefaults(String dateKey) {
    return [
      DiaryTodoItem(
        id: 'todo_vitamins_$dateKey',
        title: 'Take Vitamins & Omega-3',
        isCompleted: false,
        dateKey: dateKey,
      ),
      DiaryTodoItem(
        id: 'todo_water_$dateKey',
        title: 'Drink 1L Water',
        isCompleted: false,
        dateKey: dateKey,
      ),
      DiaryTodoItem(
        id: 'todo_stretch_$dateKey',
        title: 'Morning Mobility Stretch',
        isCompleted: false,
        dateKey: dateKey,
      ),
      DiaryTodoItem(
        id: 'todo_lunch_$dateKey',
        title: 'Log Nutritious Lunch',
        isCompleted: false,
        dateKey: dateKey,
      ),
    ];
  }

  Future<List<DiaryTodoItem>> loadTodosForDate(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kPrefix$dateKey');
    if (raw == null || raw.isEmpty) {
      final defaults = getStandardDefaults(dateKey);
      await saveTodosForDate(dateKey, defaults);
      return defaults;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => DiaryTodoItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final defaults = getStandardDefaults(dateKey);
      await saveTodosForDate(dateKey, defaults);
      return defaults;
    }
  }

  Future<void> saveTodosForDate(
    String dateKey,
    List<DiaryTodoItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString('$_kPrefix$dateKey', encoded);
  }
}

final diaryTodoServiceProvider = Provider<DiaryTodoService>((ref) {
  return DiaryTodoService();
});

class DiaryTodosNotifier extends Notifier<List<DiaryTodoItem>> {
  String _dateKey = '';

  @override
  List<DiaryTodoItem> build() {
    _dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Future.microtask(() async {
      final service = ref.read(diaryTodoServiceProvider);
      final items = await service.loadTodosForDate(_dateKey);
      state = items;
    });
    return DiaryTodoService.getStandardDefaults(_dateKey);
  }

  Future<void> loadForDate(String dateKey) async {
    _dateKey = dateKey;
    final service = ref.read(diaryTodoServiceProvider);
    final items = await service.loadTodosForDate(dateKey);
    state = items;
  }

  Future<void> toggleItem(String id) async {
    final updated = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    state = updated;
    final service = ref.read(diaryTodoServiceProvider);
    await service.saveTodosForDate(_dateKey, updated);
  }

  Future<void> addItem(String title) async {
    final newItem = DiaryTodoItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      isCompleted: false,
      dateKey: _dateKey,
      isCustom: true,
    );

    final updated = [...state, newItem];
    state = updated;
    final service = ref.read(diaryTodoServiceProvider);
    await service.saveTodosForDate(_dateKey, updated);
  }

  Future<void> deleteItem(String id) async {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    final service = ref.read(diaryTodoServiceProvider);
    await service.saveTodosForDate(_dateKey, updated);
  }
}

final diaryTodosProvider =
    NotifierProvider<DiaryTodosNotifier, List<DiaryTodoItem>>(
  DiaryTodosNotifier.new,
);

final todayDiaryDateKeyProvider = Provider<String>((ref) {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
});
