import 'dart:convert';
import 'package:crypto/crypto.dart';

enum SubmissionType {
  newExercise,
  correction;

  String toDbString() {
    switch (this) {
      case SubmissionType.newExercise:
        return 'new_exercise';
      case SubmissionType.correction:
        return 'correction';
    }
  }

  static SubmissionType fromDbString(String val) {
    if (val == 'correction') return SubmissionType.correction;
    return SubmissionType.newExercise;
  }
}

enum ModerationStatus {
  pending,
  approved,
  rejected;

  String toDbString() => name;

  static ModerationStatus fromDbString(String val) {
    switch (val.toLowerCase()) {
      case 'approved':
        return ModerationStatus.approved;
      case 'rejected':
        return ModerationStatus.rejected;
      case 'pending':
      default:
        return ModerationStatus.pending;
    }
  }
}

class ExerciseSubmission {
  final String id;
  final SubmissionType submissionType;
  final String? targetExerciseId;
  final String name;
  final String category;
  final String equipment;
  final String targetMuscle;
  final List<String> secondaryMuscles;
  final String instructions;
  final String? safetyNotes;
  final String difficultyLevel;
  final String movementType;
  final String audienceSuitability;
  final String suggestedRationale;
  final ModerationStatus status;
  final String? moderatorNotes;
  final String submittedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String duplicateHash;

  const ExerciseSubmission({
    required this.id,
    this.submissionType = SubmissionType.newExercise,
    this.targetExerciseId,
    required this.name,
    required this.category,
    required this.equipment,
    required this.targetMuscle,
    this.secondaryMuscles = const [],
    required this.instructions,
    this.safetyNotes,
    this.difficultyLevel = 'Intermediate',
    this.movementType = 'Compound',
    this.audienceSuitability = 'universal',
    this.suggestedRationale = '',
    this.status = ModerationStatus.pending,
    this.moderatorNotes,
    required this.submittedBy,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.duplicateHash,
  });

  static String generateHash({
    required SubmissionType type,
    String? targetExerciseId,
    required String name,
    required String equipment,
  }) {
    final raw =
        '${type.toDbString()}:${targetExerciseId ?? 'none'}:${name.trim().toLowerCase()}:${equipment.trim().toLowerCase()}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  ExerciseSubmission copyWith({
    String? id,
    SubmissionType? submissionType,
    String? targetExerciseId,
    String? name,
    String? category,
    String? equipment,
    String? targetMuscle,
    List<String>? secondaryMuscles,
    String? instructions,
    String? safetyNotes,
    String? difficultyLevel,
    String? movementType,
    String? audienceSuitability,
    String? suggestedRationale,
    ModerationStatus? status,
    String? moderatorNotes,
    String? submittedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? duplicateHash,
  }) {
    return ExerciseSubmission(
      id: id ?? this.id,
      submissionType: submissionType ?? this.submissionType,
      targetExerciseId: targetExerciseId ?? this.targetExerciseId,
      name: name ?? this.name,
      category: category ?? this.category,
      equipment: equipment ?? this.equipment,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      movementType: movementType ?? this.movementType,
      audienceSuitability: audienceSuitability ?? this.audienceSuitability,
      suggestedRationale: suggestedRationale ?? this.suggestedRationale,
      status: status ?? this.status,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
      submittedBy: submittedBy ?? this.submittedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      duplicateHash: duplicateHash ?? this.duplicateHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submission_type': submissionType.toDbString(),
      'target_exercise_id': targetExerciseId,
      'name': name,
      'category': category,
      'equipment': equipment,
      'target_muscle': targetMuscle,
      'secondary_muscles': secondaryMuscles,
      'instructions': instructions,
      'safety_notes': safetyNotes,
      'difficulty_level': difficultyLevel,
      'movement_type': movementType,
      'audience_suitability': audienceSuitability,
      'suggested_rationale': suggestedRationale,
      'status': status.toDbString(),
      'moderator_notes': moderatorNotes,
      'submitted_by': submittedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'duplicate_hash': duplicateHash,
    };
  }

  factory ExerciseSubmission.fromJson(Map<String, dynamic> json) {
    List<String> secMuscles = [];
    if (json['secondary_muscles'] != null) {
      if (json['secondary_muscles'] is List) {
        secMuscles = (json['secondary_muscles'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['secondary_muscles'] is String) {
        try {
          final decoded = jsonDecode(json['secondary_muscles'] as String);
          if (decoded is List) {
            secMuscles = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    return ExerciseSubmission(
      id: json['id'] as String,
      submissionType: SubmissionType.fromDbString(
        json['submission_type'] as String? ?? 'new_exercise',
      ),
      targetExerciseId: json['target_exercise_id'] as String?,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Custom',
      equipment: json['equipment'] as String? ?? 'Bodyweight',
      targetMuscle: json['target_muscle'] as String? ?? 'Full Body',
      secondaryMuscles: secMuscles,
      instructions: json['instructions'] as String? ?? '',
      safetyNotes: json['safety_notes'] as String?,
      difficultyLevel: json['difficulty_level'] as String? ?? 'Intermediate',
      movementType: json['movement_type'] as String? ?? 'Compound',
      audienceSuitability:
          json['audience_suitability'] as String? ?? 'universal',
      suggestedRationale: json['suggested_rationale'] as String? ?? '',
      status: ModerationStatus.fromDbString(
        json['status'] as String? ?? 'pending',
      ),
      moderatorNotes: json['moderator_notes'] as String?,
      submittedBy: json['submitted_by'] as String? ?? 'guest',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      duplicateHash: json['duplicate_hash'] as String? ?? '',
    );
  }
}

class ExerciseModerationLog {
  final String id;
  final String submissionId;
  final String moderatorId;
  final String action;
  final String? notes;
  final DateTime timestamp;

  const ExerciseModerationLog({
    required this.id,
    required this.submissionId,
    required this.moderatorId,
    required this.action,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'submission_id': submissionId,
    'moderator_id': moderatorId,
    'action': action,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ExerciseModerationLog.fromJson(Map<String, dynamic> json) =>
      ExerciseModerationLog(
        id: json['id'] as String,
        submissionId: json['submission_id'] as String,
        moderatorId: json['moderator_id'] as String,
        action: json['action'] as String,
        notes: json['notes'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
