/// Represents an independent, verified manual calorie-burn adjustment.
/// Stored separately from verified workouts and wearable step counts to guarantee data integrity.
class CalorieAdjustment {
  final String id;
  final String userId;
  final DateTime date; // Day to which this adjustment applies
  final int caloriesBurned;
  final String title;
  final String? note;
  final String source; // 'manual_adjustment'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;

  const CalorieAdjustment({
    required this.id,
    this.userId = 'guest',
    required this.date,
    required this.caloriesBurned,
    required this.title,
    this.note,
    this.source = 'manual_adjustment',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'synced',
  }) : assert(
         caloriesBurned > 0 && caloriesBurned <= 5000,
         'Calorie adjustment must be between 1 and 5000 kcal',
       );

  bool get isDeleted => deletedAt != null;

  CalorieAdjustment copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? caloriesBurned,
    String? title,
    String? note,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
  }) {
    return CalorieAdjustment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      title: title ?? this.title,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'calories_burned': caloriesBurned,
      'title': title,
      'note': note,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory CalorieAdjustment.fromJson(Map<String, dynamic> map) {
    return CalorieAdjustment(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'guest',
      date: DateTime.parse(map['date'] as String),
      caloriesBurned: map['calories_burned'] as int,
      title: map['title'] as String? ?? 'Manual Activity',
      note: map['note'] as String?,
      source: map['source'] as String? ?? 'manual_adjustment',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'synced',
    );
  }
}
