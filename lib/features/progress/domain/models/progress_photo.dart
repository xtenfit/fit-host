import 'package:flutter/foundation.dart';

enum PhotoPoseType {
  front,
  side,
  back,
  other;

  String get label {
    switch (this) {
      case PhotoPoseType.front:
        return 'Front Pose';
      case PhotoPoseType.side:
        return 'Side Profile';
      case PhotoPoseType.back:
        return 'Back View';
      case PhotoPoseType.other:
        return 'Detail / Other';
    }
  }

  String get value => name;

  static PhotoPoseType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'front':
        return PhotoPoseType.front;
      case 'side':
        return PhotoPoseType.side;
      case 'back':
        return PhotoPoseType.back;
      case 'other':
      default:
        return PhotoPoseType.other;
    }
  }
}

@immutable
class ProgressPhoto {
  final String id;
  final String userId;
  final DateTime takenAt;
  final String photoPath;
  final PhotoPoseType poseType;
  final String? associatedMeasurementId;
  final double? weightKgAtPhoto;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncStatus;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.takenAt,
    required this.photoPath,
    this.poseType = PhotoPoseType.front,
    this.associatedMeasurementId,
    this.weightKgAtPhoto,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus,
  });

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    DateTime? takenAt,
    String? photoPath,
    PhotoPoseType? poseType,
    String? associatedMeasurementId,
    double? weightKgAtPhoto,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncStatus,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      takenAt: takenAt ?? this.takenAt,
      photoPath: photoPath ?? this.photoPath,
      poseType: poseType ?? this.poseType,
      associatedMeasurementId:
          associatedMeasurementId ?? this.associatedMeasurementId,
      weightKgAtPhoto: weightKgAtPhoto ?? this.weightKgAtPhoto,
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
      'taken_at': takenAt.toIso8601String(),
      'photo_path': photoPath,
      'pose_type': poseType.value,
      'associated_measurement_id': associatedMeasurementId,
      'weight_kg_at_photo': weightKgAtPhoto,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'sync_status': syncStatus,
    };
  }

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'guest',
      takenAt: DateTime.parse(json['taken_at'] as String),
      photoPath: json['photo_path'] as String,
      poseType: PhotoPoseType.fromString(json['pose_type'] as String?),
      associatedMeasurementId: json['associated_measurement_id'] as String?,
      weightKgAtPhoto: (json['weight_kg_at_photo'] as num?)?.toDouble(),
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
