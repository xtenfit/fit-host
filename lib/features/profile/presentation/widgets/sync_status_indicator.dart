import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/connectivity/connectivity_state_machine.dart';
import '../../../../core/sync/sync_coordinator.dart';

class SyncStatusState {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSyncing;
  final bool isOffline;
  final DateTime? lastSyncTime;

  const SyncStatusState({
    required this.label,
    required this.icon,
    required this.color,
    this.isSyncing = false,
    this.isOffline = false,
    this.lastSyncTime,
  });
}

class SyncStatusNotifier extends Notifier<SyncStatusState> {
  Timer? _ticker;
  DateTime? _lastSyncTime;
  bool _isDraining = false;

  @override
  SyncStatusState build() {
    _lastSyncTime = null;
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => _update());

    ref.onDispose(() {
      _ticker?.cancel();
    });

    ref.listen(connectivityProvider, (prev, next) => _update());
    ref.listen(authProvider, (prev, next) => _update());

    return _computeState();
  }

  void setDraining(bool draining) {
    _isDraining = draining;
    if (!draining) {
      _lastSyncTime = DateTime.now();
    }
    _update();
  }

  void _update() {
    state = _computeState();
  }

  SyncStatusState _computeState() {
    final auth = ref.read(authProvider);
    final connectivity = ref.read(connectivityProvider).value ??
        ref.read(connectivityStateMachineProvider).currentStatus;

    if (auth.isGuest) {
      return const SyncStatusState(
        label: 'Offline — changes saved locally',
        icon: Icons.cloud_off_rounded,
        color: Colors.grey,
        isOffline: true,
      );
    }

    if (connectivity == ConnectivityStatus.offline) {
      return const SyncStatusState(
        label: 'Offline — changes saved locally',
        icon: Icons.cloud_off_rounded,
        color: AppColors.warmCoral,
        isOffline: true,
      );
    }

    if (_isDraining) {
      return const SyncStatusState(
        label: 'Syncing…',
        icon: Icons.sync_rounded,
        color: AppColors.electricCyan,
        isSyncing: true,
      );
    }

    if (_lastSyncTime == null) {
      return const SyncStatusState(
        label: 'Ready to sync',
        icon: Icons.cloud_queue_rounded,
        color: AppColors.electricCyan,
      );
    }

    final relative = _formatRelativeTime(_lastSyncTime);
    return SyncStatusState(
      label: 'Synced $relative',
      icon: Icons.cloud_done_rounded,
      color: AppColors.limeGreen,
      lastSyncTime: _lastSyncTime,
    );
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return 'just now';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }
}

final syncStatusStateProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatusState>(
        SyncStatusNotifier.new);

final recentSyncOperationsProvider =
    StreamProvider.autoDispose<List<SyncQueueData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.syncQueue)
        ..orderBy([(t) => OrderingTerm.desc(t.id)])
        ..limit(20))
      .watch();
});

final pendingSyncCountProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.syncQueue)
        ..where((t) => t.status.isIn(['queued', 'failed', 'pending'])))
      .watch()
      .map((list) => list.length);
});

class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider).value ??
        ref.watch(connectivityStateMachineProvider).currentStatus;
    final isOffline = connectivity == ConnectivityStatus.offline;
    final auth = ref.watch(authProvider);

    if (!isOffline && !auth.isOfflineGrace) {
      return const SizedBox.shrink();
    }

    final pendingCount = ref.watch(pendingSyncCountProvider).value ?? 0;
    final bannerText = pendingCount > 0
        ? 'Offline — $pendingCount change${pendingCount > 1 ? 's' : ''} saved on this device.'
        : 'Offline — changes are saved on this device.';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1508),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warmCoral.withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.warmCoral,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bannerText,
                style: const TextStyle(
                  color: AppColors.warmCoral,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                ref.read(connectivityStateMachineProvider).checkConnectivity();
                ref.read(syncCoordinatorProvider).drain().ignore();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 14, color: AppColors.warmCoral),
                    SizedBox(width: 4),
                    Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warmCoral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SyncStatusIndicator extends ConsumerWidget {
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSyncLogSheet(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: status.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.isSyncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                  ),
                )
              else
                Icon(status.icon, size: 14, color: status.color),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: status.color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSyncLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SyncLogBottomSheet(),
    );
  }
}

class _SyncLogBottomSheet extends ConsumerStatefulWidget {
  const _SyncLogBottomSheet();

  @override
  ConsumerState<_SyncLogBottomSheet> createState() =>
      _SyncLogBottomSheetState();
}

class _SyncLogBottomSheetState extends ConsumerState<_SyncLogBottomSheet> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    ref.read(syncStatusStateProvider.notifier).setDraining(true);

    try {
      final coordinator = ref.read(syncCoordinatorProvider);
      final count = await coordinator.drain();
      if (mounted) {
        setState(() => _isRetrying = false);
        ref.read(syncStatusStateProvider.notifier).setDraining(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? '✅ Successfully synced $count mutations to cloud!'
                  : 'Sync check complete. Queue is up to date.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRetrying = false);
        ref.read(syncStatusStateProvider.notifier).setDraining(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final operationsAsync = ref.watch(recentSyncOperationsProvider);
    final syncStatus = ref.watch(syncStatusStateProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceBorder
              : AppColors.lightSurfaceBorder,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: syncStatus.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(syncStatus.icon,
                          color: syncStatus.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sync Outbox Journal',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          syncStatus.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: syncStatus.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Retry Button
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Sync Now',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Operations List (Last 20)
            Expanded(
              child: operationsAsync.when(
                data: (operations) {
                  if (operations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_done_outlined,
                              size: 48,
                              color: AppColors.limeGreen.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Outbox is Clean',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All local mutations and workouts have synced to Supabase.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: operations.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final item = operations[index];
                      final isDead = item.status == 'dead_letter';
                      final isFailed = item.status == 'failed';
                      final statusColor = isDead
                          ? AppColors.error
                          : (isFailed
                              ? AppColors.warmCoral
                              : AppColors.electricCyan);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.operation.toUpperCase() == 'DELETE'
                                ? Icons.delete_outline_rounded
                                : Icons.upload_file_rounded,
                            size: 18,
                            color: statusColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.entityType.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Op: ${item.operation} • Attempts: ${item.attempts} • ${DateFormat('HH:mm:ss').format(item.clientTimestamp.toLocal())}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (item.errorLog != null &&
                                item.errorLog!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.errorLog!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading log: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
