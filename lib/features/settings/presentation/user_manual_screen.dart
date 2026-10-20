import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  int? _expandedSectionIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<_ManualSectionData> _sections = [
    const _ManualSectionData(
      title: 'Pedometer & Activity Tracking',
      icon: Icons.directions_walk_rounded,
      color: AppColors.limeGreen,
      badge: 'Sensor Real-Time',
      summary: 'Accurate step counting, treadmill manual logging & distance math',
      details: [
        _ManualItem(
          subtitle: 'Live Sensor Step Counting',
          text:
              'Fit Host interfaces with your device hardware step counter sensor. Steps are tracked continuously with real-world accuracy and stored in your encrypted local SQLite database. No synthetic or inflated numbers are generated.',
        ),
        _ManualItem(
          subtitle: 'Manual Treadmill & Indoor Session Log',
          text:
              'When walking indoors, on a treadmill, or when keeping your phone stationary, tap "+ Log Manual Treadmill Walk" on the Steps screen or Home card. Input your session step count, and Fit Host will calculate exact distance (km) and calorie burn based on your personalized height and stride length.',
        ),
        _ManualItem(
          subtitle: 'Dynamic Calorie & Distance Estimation',
          text:
              'Distance is calculated dynamically using your user profile height: distance = steps × (height × 0.415). Caloric expenditure uses an authentic MET (Metabolic Equivalent of Task) formula calibrated for walking cadence and your body weight.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Workout Tracker & Exercise Engine',
      icon: Icons.fitness_center_rounded,
      color: AppColors.electricCyan,
      badge: 'Active Engine',
      summary: 'Set logging, rest timers, 1RM calculation & muscle analytics',
      details: [
        _ManualItem(
          subtitle: 'Starting an Active Session',
          text:
              'Tap "Start Quick Workout" or choose an existing routine. The live session manager initiates an active stopwatch timer, lets you re-order exercises, and maintains state even if you switch apps.',
        ),
        _ManualItem(
          subtitle: 'Set & Weight Logging with Auto-Rest Timer',
          text:
              'Enter weight (kg or lbs) and reps. Checking off a set automatically launches the Apple-styled rest timer overlay with audio chime and haptic pulse when the rest period expires.',
        ),
        _ManualItem(
          subtitle: 'One-Rep Max (1RM) & Progressive Overload',
          text:
              'Fit Host computes your estimated 1RM using the validated Epley formula: 1RM = Weight × (1 + Reps / 30). Your historical bests are highlighted automatically during exercise logging.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Nutrition, Macro Cycling & Diet Plans',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF59E0B),
      badge: 'Diet Tailored',
      summary: 'Custom meal builder, macro distribution, and rest-day recovery',
      details: [
        _ManualItem(
          subtitle: 'Diet Preferences Adaptation',
          text:
              'Configure your dietary lifestyle in your Profile (Keto, High-Protein, Vegan, Mediterranean, Balanced). All macro target recommendations and meal builder templates automatically adapt.',
        ),
        _ManualItem(
          subtitle: 'Custom Meal Creator',
          text:
              'Create custom meals tailored to your diet. The builder computes combined protein, carbohydrate, fat, and fiber totals in real time, saving them to your local favorites.',
        ),
        _ManualItem(
          subtitle: 'Rest Day & Recovery Nutrition Menu',
          text:
              'On scheduled rest days, switch to the Rest Day menu. It emphasizes joint recovery nutrients, anti-inflammatory whole foods, increased healthy fats, and controlled carbohydrates for maximum tissue repair.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Daily Work & Life Diary + Voice Memos',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFA855F7),
      badge: 'Journal & Audio',
      summary: 'Capture work achievements, daily reflections, and voice notes',
      details: [
        _ManualItem(
          subtitle: 'Categorized Life & Work Journaling',
          text:
              'Track reflections across categories: "Work & Career", "Professional Development", "Fitness Milestones", and "Personal Life". Maintain a structured diary alongside physical progress.',
        ),
        _ManualItem(
          subtitle: 'Audio Voice Memos',
          text:
              'Record audio notes on the go using the built-in voice recorder. Audio notes are encoded locally in high-fidelity format and can be replayed with interactive scrubbing.',
        ),
        _ManualItem(
          subtitle: 'Mood & Energy Tagging',
          text:
              'Correlate your daily productivity and mental clarity with your workout recovery by selecting mood and energy state tags for each diary entry.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Alarms, Audio Tones & Reminders',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFFFFB300),
      badge: 'Audio Control',
      summary: '5 default alert sounds, device ring modes & activity mapping',
      details: [
        _ManualItem(
          subtitle: '5 Built-In Default Audio Presets',
          text:
              'Choose from 5 distinct sound profiles: Cyber Chime, Zen Bell, Energy Uplift, Titan Horn, and Midnight Radar. You can also select your device default notification tone.',
        ),
        _ManualItem(
          subtitle: 'Activity-Specific Sound Assignment',
          text:
              'Assign specific audio alerts to distinct activities: loud energetic tones for workouts, calming bells for hydration reminders, and subtle chimes for meal alerts.',
        ),
        _ManualItem(
          subtitle: 'Volume Boost & Device Overrides',
          text:
              'Enable Full Device Alert mode to ensure reminders break through low device volumes during active gym sessions.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Home Screen Widgets & Fast Shortcuts',
      icon: Icons.widgets_rounded,
      color: Color(0xFF00E5FF),
      badge: 'Widget Center',
      summary: 'Small, Medium & Large interactive widgets with quick launchers',
      details: [
        _ManualItem(
          subtitle: 'Adding Widgets to Your Home Screen',
          text:
              'On iOS: Touch and hold any empty area on your Home Screen until apps jiggle, tap "+", search "Fit Host", and select your desired widget size.\n\nOn Android: Long press any empty space on your home screen, tap "Widgets", scroll to "Fit Host", and drag to place.',
        ),
        _ManualItem(
          subtitle: 'Quick Launch Shortcuts',
          text:
              'Configure one-tap shortcuts to instantly open Active Workout, Log Steps, Record Voice Diary, or Log Water from your device home screen without navigating menus.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Health Vault, PDF & Excel Data Exports',
      icon: Icons.shield_rounded,
      color: Color(0xFF10B981),
      badge: 'E2E Encryption',
      summary: 'Comprehensive audit reports in PDF, Excel (.xlsx) and JSON',
      details: [
        _ManualItem(
          subtitle: 'Multi-Page PDF Health Audit Report',
          text:
              'Generate an official vector PDF fitness audit report with summary analytics, workout breakdowns, nutrition charts, and authenticity verification badges suitable for personal archives or sharing with a trainer.',
        ),
        _ManualItem(
          subtitle: 'Multi-Sheet Excel Workbook (.xlsx)',
          text:
              'Export an authentic Excel spreadsheet organized into clean tabs: Profile, Workouts, Sets, Steps, Nutrition, and Diary. Includes formatted headers and numerical types.',
        ),
        _ManualItem(
          subtitle: 'End-to-End Cryptography & Privacy',
          text:
              'All data is encrypted locally using SQLite cipher protection and synchronized through TLS 1.3 encryption with Supabase RLS policies. Your records remain private and under your sole ownership.',
        ),
      ],
    ),
    const _ManualSectionData(
      title: 'Support, Engineering Team & Copyrights',
      icon: Icons.support_agent_rounded,
      color: AppColors.warmCoral,
      badge: 'amitrana Team',
      summary: 'Official support channels, feedback templates, and legal notices',
      details: [
        _ManualItem(
          subtitle: 'Direct Engineering Support',
          text:
              'For assistance, custom feature requests, or technical issues, email support@amitrana.tech. The built-in Support & Feedback tool provides pre-formatted demand templates for fast responses.',
        ),
        _ManualItem(
          subtitle: 'Branding & Copyrights',
          text:
              'Fit Host is Powered by amitrana, Developed by amitrana team, and Managed by amitrana team. All trademarks, codebases, and intellectual assets are protected under © 2026 amitrana. All rights reserved.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredSections = _sections.where((section) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final titleMatch = section.title.toLowerCase().contains(q);
      final summaryMatch = section.summary.toLowerCase().contains(q);
      final detailMatch = section.details.any(
        (d) => d.subtitle.toLowerCase().contains(q) || d.text.toLowerCase().contains(q),
      );
      return titleMatch || summaryMatch || detailMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('User Manual & Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Top Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF14221A), const Color(0xFF181C28)]
                      : [const Color(0xFFEDFFF3), Colors.white],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.limeGreen.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: AppColors.limeGreen, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Fit Host Documentation',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '1.2.2v2',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.limeGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to the official interactive Fit Host User Manual. Every feature is real, precise, and engineered with Apple UI/UX standards.\nPowered by amitrana • Developed & Managed by amitrana team',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search manual (e.g. treadmill, macros, alarms, voice...)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // List of Manual Chapters
            ...List.generate(filteredSections.length, (index) {
              final section = filteredSections[index];
              final isExpanded = _expandedSectionIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isExpanded
                        ? section.color.withValues(alpha: 0.5)
                        : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                    width: isExpanded ? 1.5 : 1.0,
                  ),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey('manual_section_${section.title}'),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedSectionIndex = expanded ? index : null;
                      });
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: section.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(section.icon, color: section.color, size: 22),
                    ),
                    title: Text(
                      section.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    subtitle: Text(
                      section.summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const Divider(height: 20),
                      ...section.details.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 16, color: section.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.subtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.only(left: 24),
                                child: Text(
                                  item.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 amitrana. All rights reserved.\nEngineered & Managed by amitrana team • support@amitrana.tech',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ManualSectionData {
  final String title;
  final IconData icon;
  final Color color;
  final String badge;
  final String summary;
  final List<_ManualItem> details;

  const _ManualSectionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.badge,
    required this.summary,
    required this.details,
  });
}

class _ManualItem {
  final String subtitle;
  final String text;

  const _ManualItem({
    required this.subtitle,
    required this.text,
  });
}
