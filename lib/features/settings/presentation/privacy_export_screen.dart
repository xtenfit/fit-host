import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/database.dart';
import '../../profile/presentation/controllers/user_profile_controller.dart';
import '../data/health_export_service.dart';

final healthExportServiceProvider = Provider<HealthExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return HealthExportService(db);
});

class PrivacyExportScreen extends ConsumerStatefulWidget {
  const PrivacyExportScreen({super.key});

  @override
  ConsumerState<PrivacyExportScreen> createState() =>
      _PrivacyExportScreenState();
}

class _PrivacyExportScreenState extends ConsumerState<PrivacyExportScreen> {
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;
  bool _isExportingJson = false;
  bool _isImportingJson = false;

  File? _lastExportedFile;
  String? _lastExportType;
  String? _jsonPreview;

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      final exportService = ref.read(healthExportServiceProvider);
      final profile = ref.read(userProfileProvider);
      final file = await exportService.generatePdfAudit(profile: profile);

      setState(() {
        _isExportingPdf = false;
        _lastExportedFile = file;
        _lastExportType = 'PDF Health Audit';
      });

      await HealthExportService.shareFile(
        file,
        subject: 'Fit Host Health Audit Report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Official PDF Health Audit Report generated and ready to share!',
            ),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExportingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExportingExcel = true);
    try {
      final exportService = ref.read(healthExportServiceProvider);
      final profile = ref.read(userProfileProvider);
      final file = await exportService.generateExcelArchive(profile: profile);

      setState(() {
        _isExportingExcel = false;
        _lastExportedFile = file;
        _lastExportType = 'Excel Workbook (.xlsx)';
      });

      await HealthExportService.shareFile(
        file,
        subject: 'Fit Host Excel Fitness Data Backup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Multi-sheet Excel workbook generated! Share or save anywhere.',
            ),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExportingExcel = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportJson() async {
    setState(() => _isExportingJson = true);
    try {
      final exportService = ref.read(healthExportServiceProvider);
      final profile = ref.read(userProfileProvider);
      final file = await exportService.generateJsonArchive(profile: profile);
      final content = await file.readAsString();

      setState(() {
        _isExportingJson = false;
        _lastExportedFile = file;
        _lastExportType = 'JSON Raw Archive';
        _jsonPreview = content;
      });

      await HealthExportService.shareFile(
        file,
        subject: 'Fit Host JSON Data Archive',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Raw JSON archive created! Preview available below.',
            ),
            backgroundColor: AppColors.limeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExportingJson = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('JSON Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _importJson() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty || files.first.path == null) {
        return;
      }

      final pickedPath = files.first.path!;
      final file = File(pickedPath);
      final content = await file.readAsString();

      // Validate JSON structure
      final dynamic parsed;
      try {
        parsed = jsonDecode(content);
        if (parsed is! Map<String, dynamic>) {
          throw const FormatException('Expected JSON Object at root');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid JSON file: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final fileName = files.first.name;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Restore Backup Archive?'),
          content: Text(
            'This will merge the records from "$fileName" into your local Fit Host database.\n\nExisting records will be safely preserved or updated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Import & Merge',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isImportingJson = true);

      final exportService = ref.read(healthExportServiceProvider);
      final counts = await exportService.importJsonArchive(
        content,
        onProfileRestored: (profile) async {
          await ref.read(userProfileProvider.notifier).updateProfile(profile);
        },
      );

      setState(() => _isImportingJson = false);

      if (mounted) {
        final summaryList = counts.entries
            .map((e) => '• ${e.key}: ${e.value}')
            .join('\n');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.limeGreen),
                SizedBox(width: 8),
                Text('Import Complete'),
              ],
            ),
            content: Text(
              summaryList.isEmpty
                  ? 'All records in the backup archive were already up to date.'
                  : 'Successfully restored into your vault:\n\n$summaryList',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isImportingJson = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Backup & Data Export'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // E2E Encryption Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF132219), const Color(0xFF181C26)]
                      : [const Color(0xFFE8FDF0), Colors.white],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.limeGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End-to-End User Encrypted Vault',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your fitness logs, workouts, diary, and nutrition records are 100% real and owned by you. Export anytime with zero restrictions.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select Export & Backup Format',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Option 1: PDF Export
            _buildExportCard(
              isDark: isDark,
              title: 'Official PDF Health Audit Report',
              subtitle:
                  'Multi-page vector PDF report formatted for personal records, doctors, or trainers with verified workouts, biometrics, and activity charts.',
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.redAccent,
              badge: 'Print & Share',
              buttonLabel: _isExportingPdf
                  ? 'Compiling PDF Report...'
                  : 'Export as PDF Document',
              isLoading: _isExportingPdf,
              onPressed: _isExportingPdf ? null : _exportPdf,
            ),
            const SizedBox(height: 14),

            // Option 2: Excel Export
            _buildExportCard(
              isDark: isDark,
              title: 'Multi-Sheet Excel Workbook (.xlsx)',
              subtitle:
                  'Authentic multi-tab spreadsheet formatted for Microsoft Excel, Apple Numbers, or Google Sheets with tabs for Workouts, Sets, Steps, and Diary.',
              icon: Icons.table_chart_rounded,
              color: Colors.green,
              badge: 'Spreadsheet (.xlsx)',
              buttonLabel: _isExportingExcel
                  ? 'Building Excel Sheets...'
                  : 'Export as Excel Spreadsheet',
              isLoading: _isExportingExcel,
              onPressed: _isExportingExcel ? null : _exportExcel,
            ),
            const SizedBox(height: 14),

            // Option 3: JSON Archive
            _buildExportCard(
              isDark: isDark,
              title: 'Complete Raw JSON Data Vault',
              subtitle:
                  'Open-standard raw JSON data payload for data portability, cloud migration, and developer auditing.',
              icon: Icons.code_rounded,
              color: AppColors.electricCyan,
              badge: 'Standard JSON',
              buttonLabel: _isExportingJson
                  ? 'Assembling JSON...'
                  : 'Export as JSON Archive',
              isLoading: _isExportingJson,
              onPressed: _isExportingJson ? null : _exportJson,
            ),
            const SizedBox(height: 24),

            const Text(
              'Restore & Import Backup',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            _buildExportCard(
              isDark: isDark,
              title: 'Restore Fit Host Backup Vault',
              subtitle:
                  'Select a previously exported .json vault archive to restore workouts, biometrics, body measurements, diary entries, steps, and your profile safely with conflict resolution.',
              icon: Icons.settings_backup_restore_rounded,
              color: const Color(0xFF00E676),
              badge: 'IMPORT & RESTORE',
              buttonLabel: _isImportingJson
                  ? 'Importing Vault...'
                  : 'Select Backup JSON File',
              isLoading: _isImportingJson,
              onPressed: _isImportingJson ? null : _importJson,
            ),

            // Last Export Status Card
            if (_lastExportedFile != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.limeGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.limeGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last Backup Created: $_lastExportType',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'File saved: ${_lastExportedFile!.path.split('/').last}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => HealthExportService.shareFile(
                          _lastExportedFile!,
                          subject: 'Fit Host Data Backup',
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text(
                          'Re-Share Backup File',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // JSON Preview
            if (_jsonPreview != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'JSON Payload Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _jsonPreview!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Copied JSON to clipboard!'),
                          backgroundColor: AppColors.limeGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text(
                      'Copy JSON',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F121A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : Colors.grey[300]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _jsonPreview!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            Center(
              child: Text(
                '© 2026 amitrana. All rights reserved.\nFit Host Cryptographic Health Vault v1.3.0',
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

  Widget _buildExportCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
    required String buttonLabel,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
