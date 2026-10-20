import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class SupportFeedbackScreen extends StatefulWidget {
  const SupportFeedbackScreen({super.key});

  @override
  State<SupportFeedbackScreen> createState() => _SupportFeedbackScreenState();
}

class _SupportFeedbackScreenState extends State<SupportFeedbackScreen> {
  static const String supportEmail = 'support@amitrana.tech';

  int _selectedDemandIndex = 0;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final List<Map<String, String>> _demandTemplates = [
    {
      'title': 'Feature Demand',
      'icon': 'rocket_launch_rounded',
      'subject': '[Feature Demand] New Fitness Capability Request (v1.2.2v2)',
      'body':
          'Dear Amitrana Team,\n\nI would love to request a new feature in Fit Host:\n\n'
          '• Proposed Feature / Demand:\n[Describe your requested feature in detail]\n\n'
          '• Why this helps my fitness/routine:\n[Explain how this enhances your workflow]\n\n'
          '• Expected Behavior / Apple UI details:\n[Any specific UI or UX design expectations]\n\n'
          'Thank you for continuously improving Fit Host!\n\n'
          'Best regards,\n[Your Name / User ID]',
    },
    {
      'title': 'Diet & Workout Demand',
      'icon': 'restaurant_rounded',
      'subject': '[Custom Demand] Personalized Diet & Training Protocol (v1.2.2v2)',
      'body':
          'Dear Amitrana Nutrition & Training Team,\n\nI have a custom demand regarding my nutrition/workout plan:\n\n'
          '• Current Diet Preference: [e.g. Keto / High-Protein / Vegan / Balanced]\n'
          '• Custom Meal / Food Item Request:\n[Specify food items, custom macro ratios or recipes]\n\n'
          '• Workout Program Adjustments:\n[Specify desired exercises, split, or progression rules]\n\n'
          'Looking forward to your guidance,\n\n'
          'Best regards,\n[Your Name]',
    },
    {
      'title': 'Bug & Diagnostics',
      'icon': 'bug_report_rounded',
      'subject': '[Bug Report] Diagnostic Incident in Fit Host (v1.2.2v2)',
      'body':
          'Attention: Amitrana Technical Support Team,\n\nI encountered an unexpected behavior while using Fit Host:\n\n'
          '• Issue Description:\n[Describe what happened]\n\n'
          '• Steps to Reproduce:\n1. Open screen ...\n2. Tap on ...\n3. Observed behavior ...\n\n'
          '• Expected Result:\n[What should have occurred]\n\n'
          '• Device & OS:\n[e.g. iPhone 15 Pro / iOS 17.5 or Pixel 8 / Android 14]\n'
          '• App Version: 1.2.2v2\n\n'
          'Thank you for your prompt assistance,\n[Your Name]',
    },
    {
      'title': 'Data & Backup Support',
      'icon': 'backup_rounded',
      'subject': '[Data Support] Health Vault & Export Assistance (v1.2.2v2)',
      'body':
          'Dear Amitrana Support Team,\n\nI require assistance with my fitness data archive:\n\n'
          '• Request Type: [PDF Audit / Excel Spreadsheet / Cloud Sync / Vault Migration]\n'
          '• Details of Request:\n[Explain your data inquiry or synchronization issue]\n\n'
          '• Account Status: [Guest Local Storage / Cloud Synchronized Account]\n\n'
          'Best regards,\n[Your Name]',
    },
    {
      'title': 'General Praise & Review',
      'icon': 'favorite_rounded',
      'subject': '[Feedback] Thoughts on Fit Host Experience (v1.2.2v2)',
      'body':
          'Dear Amitrana Team,\n\nI wanted to share my feedback on using Fit Host:\n\n'
          '• What I love about Fit Host:\n[Your positive experiences, UI praise, or favorite tools]\n\n'
          '• Suggestions for the next release:\n[Any extra thoughts]\n\n'
          'Great work on the 1.2.2v2 release!\n\n'
          'Warmly,\n[Your Name]',
    },
  ];

  @override
  void initState() {
    super.initState();
    _applyTemplate(0);
  }

  void _applyTemplate(int index) {
    setState(() {
      _selectedDemandIndex = index;
      _subjectController.text = _demandTemplates[index]['subject']!;
      _bodyController.text = _demandTemplates[index]['body']!;
    });
  }

  Future<void> _launchEmail() async {
    final subject = Uri.encodeComponent(_subjectController.text.trim());
    final body = Uri.encodeComponent(_bodyController.text.trim());
    final emailUri = Uri.parse('mailto:$supportEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        await _copyToClipboard(showNotification: true);
      }
    } catch (_) {
      await _copyToClipboard(showNotification: true);
    }
  }

  Future<void> _copyToClipboard({bool showNotification = true}) async {
    final text = 'To: $supportEmail\nSubject: ${_subjectController.text}\n\n${_bodyController.text}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted && showNotification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Email draft copied to clipboard! (Ready to paste in any mail app)'),
          backgroundColor: AppColors.limeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Support & Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Email Draft',
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () => _copyToClipboard(showNotification: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Official Team Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF14202B), const Color(0xFF131722)]
                      : [const Color(0xFFE8F4FD), Colors.white],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.electricCyan.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.electricCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: AppColors.electricCyan, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Direct Engineering Support',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            Text(
                              'support@amitrana.tech',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Powered by amitrana • Developed & Managed by amitrana team\nAll feature requests, custom diet demands, and bug reports are reviewed directly by the core engineering team.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Demand Template Selector
            const Text(
              'Select Demand / Request Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_demandTemplates.length, (i) {
                  final item = _demandTemplates[i];
                  final isSelected = _selectedDemandIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) _applyTemplate(i);
                      },
                      label: Text(item['title']!),
                      selectedColor: AppColors.limeGreen.withValues(alpha: 0.25),
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark ? AppColors.limeGreen : Colors.green.shade900)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.limeGreen : (isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Subject Field
            const Text(
              'Email Subject',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.limeGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Body Field
            const Text(
              'Pre-Written Message Body (Editable)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bodyController,
              maxLines: 9,
              style: const TextStyle(fontSize: 13, height: 1.45),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                contentPadding: const EdgeInsets.all(14),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.limeGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _launchEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Send via Mail App',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(showNotification: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightSurfaceBorder,
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text(
                      'Copy Draft',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Footer Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 amitrana. All rights reserved.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fit Host Production Engine v1.2.2v2',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
