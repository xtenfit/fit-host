import 'package:flutter/foundation.dart';

@immutable
class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime measuredAt;
  final double? weightKg;
  final double? bodyFatPercentage;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? armsCm;
  final double? thighsCm;
  final double? calvesCm;
  final double? neckCm;
  final double? shouldersCm;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncStatus;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPercentage,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.armsCm,
    this.thighsCm,
    this.calvesCm,
    this.neckCm,
    this.shouldersCm,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus,
  });

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    DateTime? measuredAt,
    double? weightKg,
    double? bodyFatPercentage,
    double? waistCm,
    double? chestCm,
    double? hipsCm,
    double? armsCm,
    double? thighsCm,
    double? calvesCm,
    double? neckCm,
    double? shouldersCm,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncStatus,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      waistCm: waistCm ?? this.waistCm,
      chestCm: chestCm ?? this.chestCm,
      hipsCm: hipsCm ?? this.hipsCm,
      armsCm: armsCm ?? this.armsCm,
      thighsCm: thighsCm ?? this.thighsCm,
      calvesCm: calvesCm ?? this.calvesCm,
      neckCm: neckCm ?? this.neckCm,
      shouldersCm: shouldersCm ?? this.shouldersCm,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'measured_at': measuredAt.toIso8601String(),
      'weight_kg': weightKg,
      'body_fat_percentage': bodyFatPercentage,
      'waist_cm': waistCm,
      'chest_cm': chestCm,
      'hips_cm': hipsCm,
      'arms_cm': armsCm,
      'thighs_cm': thighsCm,
      'calves_cm': calvesCm,
      'neck_cm': neckCm,
      'shoulders_cm': shouldersCm,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'sync_status': syncStatus,
    };
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'guest',
      measuredAt: DateTime.parse(json['measured_at'] as String),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      chestCm: (json['chest_cm'] as num?)?.toDouble(),
      hipsCm: (json['hips_cm'] as num?)?.toDouble(),
      armsCm: (json['arms_cm'] as num?)?.toDouble(),
      thighsCm: (json['thighs_cm'] as num?)?.toDouble(),
      calvesCm: (json['calves_cm'] as num?)?.toDouble(),
      neckCm: (json['neck_cm'] as num?)?.toDouble(),
      shouldersCm: (json['shoulders_cm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      syncStatus: json['sync_status'] as String?,
    );
  }
}
