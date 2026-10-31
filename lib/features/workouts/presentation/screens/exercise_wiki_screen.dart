import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/exercise_submission.dart';
import '../../domain/repositories/exercise_submission_repository.dart';
import '../../data/repositories/exercise_submission_repository_impl.dart';
import '../widgets/exercise_contribution_sheet.dart';

class ExerciseWikiScreen extends ConsumerStatefulWidget {
  const ExerciseWikiScreen({super.key});

  @override
  ConsumerState<ExerciseWikiScreen> createState() => _ExerciseWikiScreenState();
}

class _ExerciseWikiScreenState extends ConsumerState<ExerciseWikiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openContributionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ExerciseContributionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repo = ref.watch(exerciseSubmissionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Exercise Wiki & Community'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.limeGreen,
          labelColor: AppColors.limeGreen,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Wiki & Standards'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'My Submissions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.limeGreen),
            tooltip: 'Propose New Exercise',
            onPressed: () => _openContributionSheet(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWikiStandardsTab(context, isDark),
          _buildMySubmissionsTab(context, isDark, repo),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.limeGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(
          'Propose Exercise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openContributionSheet(),
      ),
    );
  }

  Widget _buildWikiStandardsTab(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Governance & Provenance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkSurfaceBorder
                  : AppColors.lightSurfaceBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.limeGreen,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fit Host Verification Standards',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fit Host uses a dual-layer exercise catalog. The canonical core of 1,324 movements is '
                'verified, peer-audited, and cross-referenced with wger and exercises-dataset sources. '
                'Community submissions undergo systematic review before publication to guarantee training safety.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Three Pillars of Wiki Moderation
        _buildPillarTile(
          icon: Icons.shield_outlined,
          title: '1. Biomechanical Safety First',
          desc:
              'Instructions must detail setup, eccentric/concentric movement phases, breathing, and joint alignment. Vague or dangerous guidance is rejected.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildPillarTile(
          icon: Icons.copyright_rounded,
          title: '2. Strict Copyright & Attribution',
          desc:
              'Visual assets must have verifiable commercial or open-source licenses. Gym visual media notices and dataset origins are strictly enforced.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildPillarTile(
          icon: Icons.public_rounded,
          title: '3. Universal Non-Stereotyped Classification',
          desc:
              'Exercises are universal by default. Sex/audience specificity is only assigned when physiologically required or explicitly validated.',
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // Verified Community Wiki Section
        const Text(
          'Approved Community Additions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ExerciseSubmission>>(
          stream: ref
              .watch(exerciseSubmissionRepositoryProvider)
              .watchApprovedSubmissions(),
          builder: (context, snapshot) {
            final approved = snapshot.data ?? [];
            if (approved.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightSurfaceBorder,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 32,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No community additions published yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Be the first to propose a new movement!',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.limeGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: approved
                  .map((sub) => _buildApprovedItem(sub, isDark))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.limeGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedItem(ExerciseSubmission sub, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sub.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Community Vetted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${sub.category} • ${sub.equipment} • Target: ${sub.targetMuscle}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub.instructions,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySubmissionsTab(
    BuildContext context,
    bool isDark,
    ExerciseSubmissionRepository repo,
  ) {
    return StreamBuilder<List<ExerciseSubmission>>(
      stream: repo.watchMySubmissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data ?? [];
        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 56,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No contributions submitted yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suggest corrections to existing exercises or propose new movements.',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Propose Exercise',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openContributionSheet(),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: submissions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sub = submissions[index];
            return _buildSubmissionCard(sub, isDark);
          },
        );
      },
    );
  }

  Widget _buildSubmissionCard(ExerciseSubmission sub, bool isDark) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (sub.status) {
      case ModerationStatus.approved:
        badgeColor = AppColors.limeGreen;
        badgeText = 'Approved';
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
      case ModerationStatus.rejected:
        badgeColor = AppColors.warmCoral;
        badgeText = 'Needs Revision';
        badgeIcon = Icons.cancel_outlined;
        break;
      case ModerationStatus.pending:
        badgeColor = Colors.amber;
        badgeText = 'Pending Review';
        badgeIcon = Icons.hourglass_top_rounded;
        break;
    }

    final dateStr = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(sub.createdAt.toLocal());
    final isCorrection = sub.submissionType == SubmissionType.correction;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrection
                            ? Colors.purple.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCorrection ? 'Correction' : 'New Exercise',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCorrection
                              ? Colors.purpleAccent
                              : Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sub.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${sub.category} • ${sub.equipment} • ${sub.targetMuscle}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          if (sub.suggestedRationale.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Rationale: "${sub.suggestedRationale}"',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ],
          if (sub.moderatorNotes != null && sub.moderatorNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: badgeColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Moderator: ${sub.moderatorNotes!}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Submitted $dateStr',
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
