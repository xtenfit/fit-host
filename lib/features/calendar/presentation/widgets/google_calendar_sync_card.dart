import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/services/google_calendar_service.dart';

class GoogleCalendarSyncCard extends ConsumerStatefulWidget {
  const GoogleCalendarSyncCard({super.key});

  @override
  ConsumerState<GoogleCalendarSyncCard> createState() =>
      _GoogleCalendarSyncCardState();
}

class _GoogleCalendarSyncCardState
    extends ConsumerState<GoogleCalendarSyncCard> {
  bool _isManualSyncing = false;

  Future<void> _connect() async {
    final service = ref.read(googleCalendarServiceProvider);
    final started = await service.connectWithOAuth();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.currentState.lastError ??
                'Unable to start Google authorization.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(googleCalendarServiceProvider);
    final state =
        ref.watch(googleCalendarStateProvider).asData?.value ??
        service.currentState;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBusy =
        state.status == GoogleCalendarSyncStatus.connecting ||
        state.status == GoogleCalendarSyncStatus.syncing;

    if (state.isConnected) {
      return _ConnectedCard(
        state: state,
        isDark: isDark,
        isSyncing: _isManualSyncing || isBusy,
        onSync: () async {
          setState(() => _isManualSyncing = true);
          await ref
              .read(calendarRepositoryProvider)
              .syncPendingToGoogleCalendar();
          if (mounted) setState(() => _isManualSyncing = false);
        },
        onDisconnect: () => service.disconnect(),
      );
    }

    final statusText = switch (state.status) {
      GoogleCalendarSyncStatus.connecting => 'Opening Google authorization…',
      GoogleCalendarSyncStatus.error =>
        state.lastError ?? 'Google Calendar needs attention.',
      _ => 'Sync scheduled Fit Host events to your personal calendar.',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191F2D) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_note_rounded,
            color: isDark ? Colors.white60 : Colors.black45,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Calendar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: state.status == GoogleCalendarSyncStatus.error
                        ? Colors.redAccent
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isBusy ? null : _connect,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.electricBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    state.status == GoogleCalendarSyncStatus.error
                        ? 'Retry'
                        : 'Connect',
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  final GoogleCalendarState state;
  final bool isDark;
  final bool isSyncing;
  final VoidCallback onSync;
  final Future<void> Function() onDisconnect;

  const _ConnectedCard({
    required this.state,
    required this.isDark,
    required this.isSyncing,
    required this.onSync,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.electricBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Calendar Connected',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  state.accountEmail ?? 'Authorized Google account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (state.lastSyncedAt != null)
                  Text(
                    'Last verified: ${state.lastSyncedAt}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.sync_rounded,
                    size: 20,
                    color: AppColors.electricBlue,
                  ),
            tooltip: 'Sync now',
            onPressed: isSyncing ? null : onSync,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'disconnect') onDisconnect();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
            ],
          ),
        ],
      ),
    );
  }
}
