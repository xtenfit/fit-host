import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_host/core/database/database.dart';
import 'package:fit_host/features/workouts/data/datasources/unified_exercise_catalog_data.dart';
import 'package:fit_host/features/workouts/domain/models/workout_models.dart';
import 'package:fit_host/features/workouts/domain/repositories/routine_repository.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final AppDatabase db;
  final String userId;
  final _uuid = const Uuid();

  RoutineRepositoryImpl(this.db, {this.userId = 'guest'});

  @override
  Future<void> seedTemplateRoutines() async {
    final existing = await (db.select(
      db.routines,
    )..where((t) => t.isTemplate.equals(true))).get();
    final existingIds = existing.map((r) => r.id).toSet();

    final now = DateTime.now().toUtc();

    // Template definitions mapped to canonical Part 1 exercises
    final templates = [
      _TemplateDef(
        id: 'template_push_hypertrophy',
        name: 'Push Day: Chest, Shoulders & Triceps',
        description:
            'Comprehensive upper push workout focusing on chest pressing, vertical pressing, lateral delts, and triceps isolation.',
        category: 'Strength',
        difficulty: 'intermediate',
        durationMinutes: 45,
        tags: ['push', 'chest', 'shoulders', 'hypertrophy'],
        exercises: [
          _TemplateExercise(
            exerciseId:
                '0a01618b-0e07-59b4-929d-5e49d63a2cb2', // Incline Barbell Press
            notes: 'Keep shoulders retracted and press smoothly.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 12,
                targetWeightKg: 40.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 60.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 65.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 4,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 65.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: 'e0ba8e0b-efd0-5e42-82f1-72dec303f8a1', // Arnold Press
            notes: 'Rotate dumbbells smoothly at chin level.',
            restSeconds: 75,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 18.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 18.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 20.0,
                restSeconds: 75,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: 'e6758033-e5d5-5d3f-b132-ac7fcf020df2', // Lateral Raise
            notes:
                'Slight bend at elbows, lead with elbows up to shoulder plane.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 12,
                targetWeightKg: 10.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 12,
                targetWeightKg: 10.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'drop',
                targetReps: 15,
                targetWeightKg: 8.0,
                restSeconds: 60,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId:
                'da1e063e-24c7-5ea5-b6fb-ca3f394acb86', // Tricep Pushdown
            notes: 'Keep elbows tucked at side, fully extend at bottom.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 12,
                targetWeightKg: 25.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 30.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'failure',
                targetReps: 12,
                targetWeightKg: 30.0,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_pull_density',
        name: 'Pull Day: Back, Rear Delts & Biceps',
        description:
            'Compound pulling movements and arm flexion for back thickness, width, and arm strength.',
        category: 'Strength',
        difficulty: 'intermediate',
        durationMinutes: 50,
        tags: ['pull', 'back', 'biceps', 'hypertrophy'],
        exercises: [
          _TemplateExercise(
            exerciseId: '87517ccf-d112-51c5-b482-b2ee9f42eb1b', // Barbell Row
            notes: 'Maintain neutral spine, pull towards lower sternum.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 12,
                targetWeightKg: 40.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 60.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 70.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 4,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 70.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: 'ea15170a-6e1d-5e39-a83a-b1d13bd9fa99', // Pullup
            notes: 'Full range of motion, dead hang to chin over bar.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 0.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 0.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'failure',
                targetReps: 6,
                targetWeightKg: 0.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId:
                'afcff09d-5a46-5482-a8e3-d5ea17c19537', // Dumbbell Pullover
            notes: 'Feel the stretch in lats and serratus anterior.',
            restSeconds: 75,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 22.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 24.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 24.0,
                restSeconds: 75,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '0ddd1277-bffd-5a29-8c86-dc9cbf15a483', // Bicep Curl
            notes: 'Strict form, minimize shoulder swinging.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 12,
                targetWeightKg: 14.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 16.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'drop',
                targetReps: 12,
                targetWeightKg: 12.0,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_legs_core',
        name: 'Leg Day: Quads, Posterior Chain & Core',
        description:
            'Heavy compound lower body development targeting quadriceps, glutes, hamstrings, and isometric core stabilization.',
        category: 'Strength',
        difficulty: 'advanced',
        durationMinutes: 55,
        tags: ['legs', 'quads', 'hamstrings', 'core'],
        exercises: [
          _TemplateExercise(
            exerciseId: '451fe126-c77b-5be6-8ef3-4690d283096e', // Barbell Squat
            notes: 'Brace core, descend below parallel with controlled tempo.',
            restSeconds: 120,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 10,
                targetWeightKg: 50.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 80.0,
                restSeconds: 120,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 90.0,
                restSeconds: 120,
              ),
              _TemplateSet(
                setNumber: 4,
                setType: 'normal',
                targetReps: 6,
                targetWeightKg: 100.0,
                restSeconds: 120,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '70ed073d-9ef7-52d3-a8a8-8eed2028110a', // Deadlift
            notes: 'Drive through floor, keep bar close to shins.',
            restSeconds: 120,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 8,
                targetWeightKg: 60.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 6,
                targetWeightKg: 100.0,
                restSeconds: 120,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 5,
                targetWeightKg: 110.0,
                restSeconds: 120,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '1b3bc40e-561e-5d63-9ecb-2fcbcfb1833b', // Lunges
            notes: 'Take controlled steps, keep torso upright.',
            restSeconds: 75,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 16.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 16.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 10,
                targetWeightKg: 16.0,
                restSeconds: 75,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '9825cdb8-81c9-5273-9bac-039ab80b8f1f', // Plank
            notes:
                'Timed core hold, keep glutes squeezed and body in straight line.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'failure',
                targetReps: 1,
                durationSeconds: 90,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_conditioning_agility',
        name: 'Athletic Conditioning & Agility',
        description:
            'High-intensity athletic circuit combining calisthenics, core control, and movement endurance.',
        category: 'Cardio & Agility',
        difficulty: 'intermediate',
        durationMinutes: 40,
        tags: ['conditioning', 'hiit', 'endurance', 'cardio'],
        exercises: [
          _TemplateExercise(
            exerciseId: 'db5eb5ad-0f11-55e1-aa70-9bc984030377', // Pushup
            notes: 'Smooth cadence, chest touches ground on each rep.',
            restSeconds: 45,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 20,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 20,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 15,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '1b3bc40e-561e-5d63-9ecb-2fcbcfb1833b', // Lunges
            notes: 'Dynamic bodyweight walking lunges.',
            restSeconds: 45,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 16,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 16,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 16,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '374ada0c-ac82-5dcb-ac39-8b78123c4d84', // 3/4 Sit-Up
            notes: 'Explosive ascent, controlled descent.',
            restSeconds: 45,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 20,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 20,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 20,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '9825cdb8-81c9-5273-9bac-039ab80b8f1f', // Plank
            notes: 'Maximum duration burnout.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'failure',
                targetReps: 1,
                durationSeconds: 75,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_full_body_blitz',
        name: 'Full Body Blitz',
        description:
            'High intensity compound lifts with functional power across all major muscle groups.',
        category: 'Strength',
        difficulty: 'intermediate',
        durationMinutes: 45,
        tags: ['full-body', 'compound', 'strength', 'power'],
        exercises: [
          _TemplateExercise(
            exerciseId: '451fe126-c77b-5be6-8ef3-4690d283096e', // Barbell Squat
            notes: 'Solid foundation and deep knee flexion.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 10,
                targetWeightKg: 50.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 70.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 75.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId:
                '9da7a605-e3b6-55ae-a0a0-28f417eb3a8f', // Flat Bench Press
            notes: 'Firm arch, controlled press to lower chest.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 10,
                targetWeightKg: 40.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 60.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 65.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: 'ea15170a-6e1d-5e39-a83a-b1d13bd9fa99', // Pullup
            notes: 'Pronated grip, pull collarbone to bar.',
            restSeconds: 75,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 0.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 0.0,
                restSeconds: 75,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 6,
                targetWeightKg: 0.0,
                restSeconds: 75,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '9825cdb8-81c9-5273-9bac-039ab80b8f1f', // Plank
            notes: 'Maintain neutral spine and squeeze abdominal wall.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_upper_body_power',
        name: 'Upper Body Power Spec',
        description:
            'Maximal strength progression with heavy compound pressing and rowing movements.',
        category: 'Strength',
        difficulty: 'advanced',
        durationMinutes: 50,
        tags: ['upper-body', 'hypertrophy', 'power', 'strength'],
        exercises: [
          _TemplateExercise(
            exerciseId:
                '9da7a605-e3b6-55ae-a0a0-28f417eb3a8f', // Flat Bench Press
            notes: 'Heavy working sets with strict eccentric cadence.',
            restSeconds: 120,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'warmup',
                targetReps: 10,
                targetWeightKg: 40.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 6,
                targetWeightKg: 70.0,
                restSeconds: 120,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 6,
                targetWeightKg: 75.0,
                restSeconds: 120,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId:
                'c589ed7d-b627-58f5-8c93-f58f27050f59', // Dumbbell Incline Bench Press
            notes: 'Incline bench at 30 degrees, full stretch at bottom.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 22.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 24.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 24.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId:
                'bb9a1e5e-39a6-55fd-841f-2fe682cfee58', // Barbell Seated Overhead Press
            notes: 'Press straight overhead, clear head smoothly.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 35.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 40.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 6,
                targetWeightKg: 42.5,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '87517ccf-d112-51c5-b482-b2ee9f42eb1b', // Barbell Row
            notes: 'Retract scapulae firmly at top of pull.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 55.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 60.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 60.0,
                restSeconds: 90,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_core_mobility',
        name: 'Core & Kinetic Mobility',
        description:
            'Spinal decompression, deep core activation, and posterior chain stabilization.',
        category: 'Mobility',
        difficulty: 'beginner',
        durationMinutes: 30,
        tags: ['core', 'mobility', 'stability', 'recovery'],
        exercises: [
          _TemplateExercise(
            exerciseId: '9825cdb8-81c9-5273-9bac-039ab80b8f1f', // Plank
            notes: 'Forearm hold with glute squeeze.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'failure',
                targetReps: 1,
                durationSeconds: 75,
                restSeconds: 60,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '1b3bc40e-561e-5d63-9ecb-2fcbcfb1833b', // Lunges
            notes: 'Dynamic hip flexor opening lunges.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 12,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 12,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '374ada0c-ac82-5dcb-ac39-8b78123c4d84', // 3/4 Sit-Up
            notes: 'Controlled flexion, focus on rectus abdominis.',
            restSeconds: 45,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 15,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 15,
                targetWeightKg: 0.0,
                restSeconds: 45,
              ),
            ],
          ),
        ],
      ),
      _TemplateDef(
        id: 'template_calisthenics_foundations',
        name: 'Calisthenics Foundations',
        description:
            'Pure bodyweight mastery targeting push, pull, leg power, and core endurance.',
        category: 'Bodyweight',
        difficulty: 'intermediate',
        durationMinutes: 35,
        tags: ['calisthenics', 'bodyweight', 'pushup', 'pullup'],
        exercises: [
          _TemplateExercise(
            exerciseId: 'db5eb5ad-0f11-55e1-aa70-9bc984030377', // Pushup
            notes: 'Strict cadence, chest touches floor.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 15,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 15,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'failure',
                targetReps: 12,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: 'ea15170a-6e1d-5e39-a83a-b1d13bd9fa99', // Pullup
            notes: 'Dead hang to chin completely over bar.',
            restSeconds: 90,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 0.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 8,
                targetWeightKg: 0.0,
                restSeconds: 90,
              ),
              _TemplateSet(
                setNumber: 3,
                setType: 'failure',
                targetReps: 6,
                targetWeightKg: 0.0,
                restSeconds: 90,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '1b3bc40e-561e-5d63-9ecb-2fcbcfb1833b', // Lunges
            notes: 'Dynamic bodyweight walking lunges.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 14,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'normal',
                targetReps: 14,
                targetWeightKg: 0.0,
                restSeconds: 60,
              ),
            ],
          ),
          _TemplateExercise(
            exerciseId: '9825cdb8-81c9-5273-9bac-039ab80b8f1f', // Plank
            notes: 'High plank or elbow plank hold.',
            restSeconds: 60,
            sets: [
              _TemplateSet(
                setNumber: 1,
                setType: 'normal',
                targetReps: 1,
                durationSeconds: 60,
                restSeconds: 60,
              ),
              _TemplateSet(
                setNumber: 2,
                setType: 'failure',
                targetReps: 1,
                durationSeconds: 75,
                restSeconds: 60,
              ),
            ],
          ),
        ],
      ),
    ];

    final existingExRows = await (db.selectOnly(
      db.exercises,
    )..addColumns([db.exercises.id])).get();
    final knownExIds = existingExRows
        .map((r) => r.read(db.exercises.id))
        .whereType<String>()
        .toSet();

    await db.transaction(() async {
      for (final t in templates) {
        if (existingIds.contains(t.id)) continue;
        await db
            .into(db.routines)
            .insert(
              RoutinesCompanion.insert(
                id: t.id,
                userId: const Value('system'),
                name: t.name,
                description: Value(t.description),
                category: Value(t.category),
                difficulty: Value(t.difficulty),
                estimatedDurationMinutes: Value(t.durationMinutes),
                isTemplate: const Value(true),
                isArchived: const Value(false),
                tags: Value(jsonEncode(t.tags)),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        for (var i = 0; i < t.exercises.length; i++) {
          final te = t.exercises[i];
          if (!knownExIds.contains(te.exerciseId)) {
            await db
                .into(db.exercises)
                .insert(
                  ExercisesCompanion.insert(
                    id: te.exerciseId,
                    name:
                        'Template Exercise ${te.exerciseId.length > 8 ? te.exerciseId.substring(0, 8) : te.exerciseId}',
                    category: 'General',
                    targetMuscle: 'Full Body',
                    instructions: 'Standard form execution.',
                    equipment: 'bodyweight',
                    createdAt: now,
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
            knownExIds.add(te.exerciseId);
          }
          final reId = '${t.id}_re_$i';
          await db
              .into(db.routineExercises)
              .insert(
                RoutineExercisesCompanion.insert(
                  id: reId,
                  routineId: t.id,
                  exerciseId: te.exerciseId,
                  userId: const Value('system'),
                  orderIndex: Value(i),
                  notes: Value(te.notes),
                  restSeconds: Value(te.restSeconds),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );

          for (var sIdx = 0; sIdx < te.sets.length; sIdx++) {
            final ts = te.sets[sIdx];
            await db
                .into(db.routineSets)
                .insert(
                  RoutineSetsCompanion.insert(
                    id: '${reId}_set_$sIdx',
                    routineExerciseId: reId,
                    userId: const Value('system'),
                    setNumber: ts.setNumber,
                    setType: Value(ts.setType),
                    targetReps: Value(ts.targetReps),
                    targetWeightKg: Value(ts.targetWeightKg),
                    targetDurationSeconds: Value(ts.durationSeconds),
                    restSeconds: Value(ts.restSeconds),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                  ),
                );
          }
        }
      }
    });
  }

  @override
  Future<List<RoutineEntity>> getRoutines({
    bool includeArchived = false,
  }) async {
    final query = db.select(db.routines)
      ..where(
        (t) =>
            (t.userId.equals(userId) | t.isTemplate.equals(true)) &
            t.isDeleted.equals(false),
      );

    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.isTemplate, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);

    final rows = await query.get();
    final result = <RoutineEntity>[];
    for (final row in rows) {
      final r = await getRoutineById(row.id);
      if (r != null) result.add(r);
    }
    return result;
  }

  @override
  Stream<List<RoutineEntity>> watchRoutines({bool includeArchived = false}) {
    final query = db.select(db.routines)
      ..where(
        (t) =>
            (t.userId.equals(userId) | t.isTemplate.equals(true)) &
            t.isDeleted.equals(false),
      );

    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.isTemplate, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch().asyncMap((rows) async {
      final result = <RoutineEntity>[];
      for (final row in rows) {
        final r = await getRoutineById(row.id);
        if (r != null) result.add(r);
      }
      return result;
    });
  }

  @override
  Future<RoutineEntity?> getRoutineById(String id) async {
    final rRow =
        await (db.select(db.routines)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();

    if (rRow == null) return null;

    final reRows =
        await (db.select(db.routineExercises)
              ..where((t) => t.routineId.equals(id) & t.isDeleted.equals(false))
              ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
            .get();

    final exercises = <RoutineExerciseEntity>[];
    for (final re in reRows) {
      var exRow = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals(re.exerciseId))).getSingleOrNull();

      if (exRow == null) {
        final mapping =
            await (db.select(db.exerciseIdMappings)
                  ..where((t) => t.oldExerciseId.equals(re.exerciseId)))
                .getSingleOrNull();
        if (mapping != null) {
          exRow =
              await (db.select(db.exercises)
                    ..where((t) => t.id.equals(mapping.canonicalExerciseId)))
                  .getSingleOrNull();
        }
      }

      String exerciseName = exRow?.name ?? '';
      String category = exRow?.category ?? '';

      if (exerciseName.isEmpty || exerciseName == 'Unknown Exercise') {
        final canonicalId =
            kLegacyExerciseMappings[re.exerciseId] ?? re.exerciseId;
        final catalogItem = kUnifiedExerciseCatalog
            .where((e) => e.id == canonicalId || e.id == re.exerciseId)
            .firstOrNull;
        if (catalogItem != null) {
          exerciseName = catalogItem.name;
          category = catalogItem.category;
        } else {
          exerciseName = _humanizeExerciseSlug(re.exerciseId);
          category = 'Strength';
        }
      }

      final sRows =
          await (db.select(db.routineSets)
                ..where(
                  (t) =>
                      t.routineExerciseId.equals(re.id) &
                      t.isDeleted.equals(false),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.setNumber)]))
              .get();

      final sets = sRows
          .map(
            (s) => RoutineSetEntity(
              id: s.id,
              routineExerciseId: s.routineExerciseId,
              setNumber: s.setNumber,
              type: s.setType,
              targetReps: s.targetReps,
              targetWeightKg: s.targetWeightKg,
              durationSeconds: s.targetDurationSeconds,
              distanceMeters: s.targetDistanceMeters,
              tempo: s.tempo,
              rpe: s.targetRpe,
              restSeconds: s.restSeconds,
            ),
          )
          .toList();

      exercises.add(
        RoutineExerciseEntity(
          id: re.id,
          routineId: re.routineId,
          exerciseId: re.exerciseId,
          exerciseName: exerciseName,
          category: category.isNotEmpty ? category : 'General',
          orderIndex: re.orderIndex,
          notes: re.notes,
          supersetId: re.supersetId,
          restSeconds: re.restSeconds,
          sets: sets,
        ),
      );
    }

    List<String> tags = [];
    try {
      final decoded = jsonDecode(rRow.tags);
      if (decoded is List) tags = decoded.map((e) => e.toString()).toList();
    } catch (_) {}

    return RoutineEntity(
      id: rRow.id,
      userId: rRow.userId,
      name: rRow.name,
      description: rRow.description,
      category: rRow.category,
      difficulty: rRow.difficulty,
      estimatedDurationMinutes: rRow.estimatedDurationMinutes,
      isTemplate: rRow.isTemplate,
      isArchived: rRow.isArchived,
      tags: tags,
      createdAt: rRow.createdAt,
      updatedAt: rRow.updatedAt,
      exercises: exercises,
    );
  }

  @override
  Future<void> saveRoutine(RoutineEntity routine) async {
    final now = DateTime.now().toUtc();
    final effectiveUserId = routine.isTemplate ? 'system' : userId;

    await db.transaction(() async {
      await db
          .into(db.routines)
          .insertOnConflictUpdate(
            RoutinesCompanion.insert(
              id: routine.id,
              userId: Value(effectiveUserId),
              name: routine.name,
              description: Value(routine.description),
              category: Value(routine.category),
              difficulty: Value(routine.difficulty),
              estimatedDurationMinutes: Value(routine.estimatedDurationMinutes),
              isTemplate: Value(routine.isTemplate),
              isArchived: Value(routine.isArchived),
              tags: Value(jsonEncode(routine.tags)),
              createdAt: Value(routine.createdAt.toUtc()),
              updatedAt: Value(now),
              isDeleted: const Value(false),
            ),
          );

      // Clean old exercises & sets for this routine
      final existingWe = await (db.select(
        db.routineExercises,
      )..where((t) => t.routineId.equals(routine.id))).get();
      for (final we in existingWe) {
        await (db.delete(
          db.routineSets,
        )..where((s) => s.routineExerciseId.equals(we.id))).go();
      }
      await (db.delete(
        db.routineExercises,
      )..where((t) => t.routineId.equals(routine.id))).go();

      // Insert new exercises & sets
      for (var i = 0; i < routine.exercises.length; i++) {
        final re = routine.exercises[i];
        final reId = re.id.isEmpty ? 're_${_uuid.v4()}' : re.id;

        await db
            .into(db.routineExercises)
            .insert(
              RoutineExercisesCompanion.insert(
                id: reId,
                routineId: routine.id,
                exerciseId: re.exerciseId,
                userId: Value(effectiveUserId),
                orderIndex: Value(i),
                notes: Value(re.notes),
                supersetId: Value(re.supersetId),
                restSeconds: Value(re.restSeconds ?? 60),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        for (var sIdx = 0; sIdx < re.sets.length; sIdx++) {
          final rs = re.sets[sIdx];
          final rsId = rs.id.isEmpty ? 'rs_${_uuid.v4()}' : rs.id;

          await db
              .into(db.routineSets)
              .insert(
                RoutineSetsCompanion.insert(
                  id: rsId,
                  routineExerciseId: reId,
                  userId: Value(effectiveUserId),
                  setNumber: sIdx + 1,
                  setType: Value(rs.type),
                  targetReps: Value(rs.targetReps),
                  targetWeightKg: Value(rs.targetWeightKg),
                  targetDurationSeconds: Value(rs.durationSeconds),
                  targetDistanceMeters: Value(rs.distanceMeters),
                  targetRpe: Value(rs.rpe),
                  tempo: Value(rs.tempo),
                  restSeconds: Value(rs.restSeconds),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
        }
      }

      // Add to syncQueue if user routine
      if (!routine.isTemplate) {
        await db
            .into(db.syncQueue)
            .insertOnConflictUpdate(
              SyncQueueCompanion.insert(
                id: 'sync-routine-${routine.id}',
                userId: Value(userId),
                entityType: 'routine',
                entityId: routine.id,
                operation: 'upsert',
                payload: jsonEncode({
                  'id': routine.id,
                  'user_id': userId,
                  'name': routine.name,
                  'description': routine.description,
                  'category': routine.category,
                  'difficulty': routine.difficulty,
                  'estimated_duration_minutes':
                      routine.estimatedDurationMinutes,
                  'is_template': false,
                  'is_archived': routine.isArchived,
                  'tags': routine.tags,
                  'updated_at': now.toIso8601String(),
                }),
                createdAt: now,
                clientTimestamp: Value(now),
                status: const Value('queued'),
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteRoutine(String id) async {
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await (db.update(db.routines)..where((t) => t.id.equals(id))).write(
        RoutinesCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await db
          .into(db.syncQueue)
          .insertOnConflictUpdate(
            SyncQueueCompanion.insert(
              id: 'sync-delete-routine-$id',
              userId: Value(userId),
              entityType: 'routine',
              entityId: id,
              operation: 'delete',
              payload: jsonEncode({'id': id, 'user_id': userId}),
              createdAt: now,
              clientTimestamp: Value(now),
              status: const Value('queued'),
            ),
          );
    });
  }

  @override
  Future<RoutineEntity> duplicateRoutine(
    String routineId, {
    String? newName,
  }) async {
    final original = await getRoutineById(routineId);
    if (original == null) {
      throw ArgumentError('Routine with ID $routineId not found');
    }

    final newRoutineId = 'routine_${_uuid.v4()}';
    final name = newName ?? '${original.name} (Copy)';
    final now = DateTime.now().toUtc();

    final duplicatedExercises = original.exercises.map((e) {
      final newExerciseId = 're_${_uuid.v4()}';
      final duplicatedSets = e.sets.map((s) {
        return s.copyWith(
          id: 'rs_${_uuid.v4()}',
          routineExerciseId: newExerciseId,
        );
      }).toList();

      return e.copyWith(
        id: newExerciseId,
        routineId: newRoutineId,
        sets: duplicatedSets,
      );
    }).toList();

    final duplicated = RoutineEntity(
      id: newRoutineId,
      userId: userId,
      name: name,
      description: original.description,
      category: original.category,
      difficulty: original.difficulty,
      estimatedDurationMinutes: original.estimatedDurationMinutes,
      isTemplate: false,
      isArchived: false,
      tags: List.from(original.tags),
      createdAt: now,
      updatedAt: now,
      exercises: duplicatedExercises,
    );

    await saveRoutine(duplicated);
    return duplicated;
  }

  @override
  Future<void> archiveRoutine(String routineId, {bool archive = true}) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.routines)..where((t) => t.id.equals(routineId))).write(
      RoutinesCompanion(isArchived: Value(archive), updatedAt: Value(now)),
    );

    await db
        .into(db.syncQueue)
        .insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: 'sync-archive-routine-$routineId',
            userId: Value(userId),
            entityType: 'routine',
            entityId: routineId,
            operation: 'upsert',
            payload: jsonEncode({
              'id': routineId,
              'user_id': userId,
              'is_archived': archive,
              'updated_at': now.toIso8601String(),
            }),
            createdAt: now,
            clientTimestamp: Value(now),
            status: const Value('queued'),
          ),
        );
  }

  // Personal Records
  @override
  Future<List<PersonalRecordEntity>> getPersonalRecords({
    String? exerciseId,
  }) async {
    final query = db.select(db.personalRecords)
      ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));

    if (exerciseId != null) {
      query.where((t) => t.exerciseId.equals(exerciseId));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.achievedAt, mode: OrderingMode.desc),
    ]);
    final rows = await query.get();

    return rows
        .map(
          (r) => PersonalRecordEntity(
            id: r.id,
            userId: r.userId,
            exerciseId: r.exerciseId,
            recordType: r.recordType,
            value: r.value,
            weightKg: r.weightKg,
            reps: r.reps,
            durationSeconds: r.durationSeconds,
            workoutId: r.workoutId,
            workoutSetId: r.workoutSetId,
            achievedAt: r.achievedAt,
          ),
        )
        .toList();
  }

  @override
  Future<PersonalRecordEntity?> getPersonalRecord(
    String exerciseId,
    String recordType,
  ) async {
    final row =
        await (db.select(db.personalRecords)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.exerciseId.equals(exerciseId) &
                    t.recordType.equals(recordType) &
                    t.isDeleted.equals(false),
              )
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.value, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (row == null) return null;

    return PersonalRecordEntity(
      id: row.id,
      userId: row.userId,
      exerciseId: row.exerciseId,
      recordType: row.recordType,
      value: row.value,
      weightKg: row.weightKg,
      reps: row.reps,
      durationSeconds: row.durationSeconds,
      workoutId: row.workoutId,
      workoutSetId: row.workoutSetId,
      achievedAt: row.achievedAt,
    );
  }

  @override
  Future<void> savePersonalRecord(PersonalRecordEntity pr) async {
    final now = DateTime.now().toUtc();
    await db
        .into(db.personalRecords)
        .insertOnConflictUpdate(
          PersonalRecordsCompanion.insert(
            id: pr.id,
            userId: Value(userId),
            exerciseId: pr.exerciseId,
            recordType: pr.recordType,
            value: pr.value,
            weightKg: Value(pr.weightKg),
            reps: Value(pr.reps),
            durationSeconds: Value(pr.durationSeconds),
            workoutId: Value(pr.workoutId),
            workoutSetId: Value(pr.workoutSetId),
            achievedAt: pr.achievedAt,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  // Progression Settings
  @override
  Future<ProgressionSettingsEntity?> getProgressionSettings(
    String exerciseId,
  ) async {
    final row =
        await (db.select(db.progressionSettings)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.exerciseId.equals(exerciseId) &
                  t.isDeleted.equals(false),
            ))
            .getSingleOrNull();

    if (row == null) return null;

    return ProgressionSettingsEntity(
      id: row.id,
      userId: row.userId,
      exerciseId: row.exerciseId,
      strategy: row.strategy,
      targetRepsMin: row.targetRepsMin,
      targetRepsMax: row.targetRepsMax,
      targetWorkingSets: row.targetWorkingSets,
      successfulSessionsRequired: row.successfulSessionsRequired,
      weightIncrementKg: row.weightIncrementKg,
      unitSystem: row.unitSystem,
      autoApply: row.autoApply,
      deloadAfterMissedSessions: row.deloadAfterMissedSessions,
      deloadPercentage: row.deloadPercentage,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> saveProgressionSettings(
    ProgressionSettingsEntity settings,
  ) async {
    final now = DateTime.now().toUtc();
    await db
        .into(db.progressionSettings)
        .insertOnConflictUpdate(
          ProgressionSettingsCompanion.insert(
            id: settings.id,
            userId: Value(userId),
            exerciseId: settings.exerciseId ?? '',
            strategy: Value(settings.strategy),
            targetRepsMin: Value(settings.targetRepsMin),
            targetRepsMax: Value(settings.targetRepsMax),
            targetWorkingSets: Value(settings.targetWorkingSets),
            successfulSessionsRequired: Value(
              settings.successfulSessionsRequired,
            ),
            weightIncrementKg: Value(settings.weightIncrementKg),
            unitSystem: Value(settings.unitSystem),
            autoApply: Value(settings.autoApply),
            deloadAfterMissedSessions: Value(
              settings.deloadAfterMissedSessions,
            ),
            deloadPercentage: Value(settings.deloadPercentage),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  String _humanizeExerciseSlug(String id) {
    final clean = id.replaceAll(RegExp(r'^ex-'), '').replaceAll('-', ' ');
    return clean
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}

class _TemplateDef {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final List<String> tags;
  final List<_TemplateExercise> exercises;

  const _TemplateDef({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.tags,
    required this.exercises,
  });
}

class _TemplateExercise {
  final String exerciseId;
  final String? notes;
  final int restSeconds;
  final List<_TemplateSet> sets;

  const _TemplateExercise({
    required this.exerciseId,
    this.notes,
    this.restSeconds = 60,
    required this.sets,
  });
}

class _TemplateSet {
  final int setNumber;
  final String setType;
  final int targetReps;
  final double? targetWeightKg;
  final int? durationSeconds;
  final int restSeconds;

  const _TemplateSet({
    required this.setNumber,
    required this.setType,
    required this.targetReps,
    this.targetWeightKg,
    this.durationSeconds,
    this.restSeconds = 60,
  });
}
