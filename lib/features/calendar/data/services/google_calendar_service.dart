import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleCalendarInfo {
  final String id;
  final String summary;
  final bool isPrimary;
  final String timeZone;

  const GoogleCalendarInfo({
    required this.id,
    required this.summary,
    this.isPrimary = false,
    required this.timeZone,
  });

  factory GoogleCalendarInfo.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarInfo(
      id: json['id'] as String? ?? 'primary',
      summary: json['summary'] as String? ?? 'Primary Calendar',
      isPrimary: json['primary'] as bool? ?? false,
      timeZone: json['timeZone'] as String? ?? 'UTC',
    );
  }
}

enum GoogleCalendarSyncStatus {
  disconnected,
  connecting,
  connected,
  syncing,
  error,
}

class GoogleCalendarState {
  final GoogleCalendarSyncStatus status;
  final String? accountEmail;
  final String selectedCalendarId;
  final String? lastError;
  final DateTime? lastSyncedAt;

  const GoogleCalendarState({
    this.status = GoogleCalendarSyncStatus.disconnected,
    this.accountEmail,
    this.selectedCalendarId = 'primary',
    this.lastError,
    this.lastSyncedAt,
  });

  bool get isConnected =>
      status == GoogleCalendarSyncStatus.connected ||
      status == GoogleCalendarSyncStatus.syncing;

  GoogleCalendarState copyWith({
    GoogleCalendarSyncStatus? status,
    String? accountEmail,
    String? selectedCalendarId,
    String? lastError,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return GoogleCalendarState(
      status: status ?? this.status,
      accountEmail: accountEmail ?? this.accountEmail,
      selectedCalendarId: selectedCalendarId ?? this.selectedCalendarId,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class GoogleCalendarService {
  static const String _kAccessTokenKey = 'fit_host_gcal_access_token';
  static const String _kRefreshTokenKey = 'fit_host_gcal_refresh_token';
  static const String _kEmailKey = 'fit_host_gcal_email';
  static const String _kUserIdKey = 'fit_host_gcal_user_id';
  static const String _kCalendarIdKey = 'fit_host_gcal_calendar_id';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  String? _cachedAccessToken;
  String? _cachedEmail;
  String _selectedCalendarId = 'primary';
  final _stateController = StreamController<GoogleCalendarState>.broadcast();

  GoogleCalendarState _currentState = const GoogleCalendarState();
  GoogleCalendarState get currentState => _currentState;
  Stream<GoogleCalendarState> get stateStream => _stateController.stream;
  String? get cachedEmail => _cachedEmail;

  GoogleCalendarService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client() {
    _loadPersistedAuth();
    try {
      final auth = Supabase.instance.client.auth;
      auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session?.providerToken?.isNotEmpty == true) {
          _acceptProviderSession(session!);
        }
      });
      final session = auth.currentSession;
      if (session?.providerToken?.isNotEmpty == true) {
        _acceptProviderSession(session!);
      }
    } catch (e) {
      debugPrint('[GoogleCalendarService] OAuth listener unavailable: $e');
    }
  }

  void _updateState(GoogleCalendarState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  Future<void> _loadPersistedAuth() async {
    try {
      final token = await _storage.read(key: _kAccessTokenKey);
      final email = await _storage.read(key: _kEmailKey);
      final storedUserId = await _storage.read(key: _kUserIdKey);
      final calId = await _storage.read(key: _kCalendarIdKey) ?? 'primary';
      String? currentUserId;
      try {
        currentUserId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      if (token != null &&
          token.isNotEmpty &&
          storedUserId != null &&
          storedUserId == currentUserId &&
          await _verifyAccessToken(token)) {
        _cachedAccessToken = token;
        _cachedEmail = email;
        _selectedCalendarId = calId;
        _updateState(
          _currentState.copyWith(
            status: GoogleCalendarSyncStatus.connected,
            accountEmail: email,
            selectedCalendarId: calId,
          ),
        );
      }
    } catch (e) {
      debugPrint('[GoogleCalendarService] Secure storage read error: $e');
    }
  }

  Future<bool> connectWithOAuth() async {
    _updateState(
      _currentState.copyWith(
        status: GoogleCalendarSyncStatus.connecting,
        clearError: true,
      ),
    );

    try {
      final auth = Supabase.instance.client.auth;
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw StateError(
          'Sign in to Fit Host before connecting Google Calendar.',
        );
      }

      final launched = await auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: 'io.supabase.fithost://calendar-callback',
        scopes: 'https://www.googleapis.com/auth/calendar.events',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _updateState(
          _currentState.copyWith(
            status: GoogleCalendarSyncStatus.disconnected,
            lastError: 'Google authorization was cancelled.',
          ),
        );
      }
      return launched;
    } catch (e) {
      final String message;
      if (e is AuthException) {
        if (e.message.toLowerCase().contains('already linked')) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null && session.providerToken != null) {
            await _acceptProviderSession(session);
            return true;
          }
          message =
              'Google account is already linked. Please check Calendar permissions.';
        } else {
          message = 'Google authorization failed: ${e.message}';
        }
      } else {
        message =
            'Google authorization could not be started: ${e.toString().replaceAll('Exception:', '').replaceAll('StateError:', '').trim()}';
      }
      _updateState(
        _currentState.copyWith(
          status: GoogleCalendarSyncStatus.error,
          lastError: message,
        ),
      );
      return false;
    }
  }

  Future<void> _acceptProviderSession(Session session) async {
    final token = session.providerToken;
    if (token == null || token.isEmpty || !await _verifyAccessToken(token)) {
      _updateState(
        _currentState.copyWith(
          status: GoogleCalendarSyncStatus.error,
          lastError:
              'Google authorization succeeded, but Calendar access could not be verified.',
        ),
      );
      return;
    }
    _cachedAccessToken = token;
    _cachedEmail = session.user.email;
    await _storage.write(key: _kAccessTokenKey, value: token);
    await _storage.write(key: _kUserIdKey, value: session.user.id);
    if (session.providerRefreshToken != null) {
      await _storage.write(
        key: _kRefreshTokenKey,
        value: session.providerRefreshToken,
      );
    }
    if (_cachedEmail != null) {
      await _storage.write(key: _kEmailKey, value: _cachedEmail);
    }
    _updateState(
      _currentState.copyWith(
        status: GoogleCalendarSyncStatus.connected,
        accountEmail: _cachedEmail,
        selectedCalendarId: _selectedCalendarId,
        clearError: true,
      ),
    );
  }

  Future<bool> _verifyAccessToken(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/users/me/calendarList?maxResults=1',
        ),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.acceptHeader: 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[GoogleCalendarService] Calendar verification failed: $e');
      return false;
    }
  }

  /// Disconnect and purge tokens securely
  Future<void> disconnect() async {
    _cachedAccessToken = null;
    _cachedEmail = null;
    try {
      await _storage.delete(key: _kAccessTokenKey);
      await _storage.delete(key: _kRefreshTokenKey);
      await _storage.delete(key: _kEmailKey);
      await _storage.delete(key: _kUserIdKey);
      await _storage.delete(key: _kCalendarIdKey);
    } catch (e) {
      debugPrint('[GoogleCalendarService] Storage purge notice: $e');
    }
    _updateState(
      const GoogleCalendarState(status: GoogleCalendarSyncStatus.disconnected),
    );
  }

  /// Select target calendar
  Future<void> setSelectedCalendar(String calendarId) async {
    _selectedCalendarId = calendarId;
    await _storage.write(key: _kCalendarIdKey, value: calendarId);
    _updateState(_currentState.copyWith(selectedCalendarId: calendarId));
  }

  /// List available Google Calendars for this user
  Future<List<GoogleCalendarInfo>> listCalendars() async {
    final token = _cachedAccessToken;
    if (token == null) return [];

    try {
      final response = await _client.get(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/users/me/calendarList',
        ),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.acceptHeader: 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items
            .map(
              (item) =>
                  GoogleCalendarInfo.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[GoogleCalendarService] listCalendars error: $e');
    }
    return [];
  }

  /// Create an event in Google Calendar with idempotency to avoid duplicates
  Future<String?> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? timeZone,
    List<int> reminderMinutesBefore = const [15],
    String? idempotencyKey, // stable iCalUID or client mutation ID
  }) async {
    final token = _cachedAccessToken;
    if (token == null) {
      debugPrint('[GoogleCalendarService] Skipping createEvent: not connected');
      return null;
    }

    _updateState(
      _currentState.copyWith(status: GoogleCalendarSyncStatus.syncing),
    );

    try {
      if (idempotencyKey != null) {
        final existingId = await _findEventByICalUid(idempotencyKey);
        if (existingId != null) {
          _updateState(
            _currentState.copyWith(
              status: GoogleCalendarSyncStatus.connected,
              lastSyncedAt: DateTime.now(),
              clearError: true,
            ),
          );
          return existingId;
        }
      }
      final localTz = timeZone ?? DateTime.now().timeZoneName;
      final bodyMap = <String, dynamic>{
        'summary': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'start': {
          'dateTime': startTime.toUtc().toIso8601String(),
          'timeZone': localTz,
        },
        'end': {
          'dateTime': endTime.toUtc().toIso8601String(),
          'timeZone': localTz,
        },
        if (idempotencyKey != null)
          'iCalUID': '$idempotencyKey@fithost.amitrana.tech',
        'reminders': {
          'useDefault': reminderMinutesBefore.isEmpty,
          'overrides': reminderMinutesBefore
              .map((min) => {'method': 'popup', 'minutes': min})
              .toList(),
        },
      };

      final calendarId = Uri.encodeComponent(_selectedCalendarId);
      final response = await _client.post(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events',
        ),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final eventId = data['id'] as String?;
        _updateState(
          _currentState.copyWith(
            status: GoogleCalendarSyncStatus.connected,
            lastSyncedAt: DateTime.now(),
          ),
        );
        return eventId;
      } else {
        _updateState(
          _currentState.copyWith(
            status: GoogleCalendarSyncStatus.connected,
            lastError:
                'Google Calendar API error ${response.statusCode}: ${response.body}',
          ),
        );
        return null;
      }
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: GoogleCalendarSyncStatus.connected,
          lastError: 'Event creation failed: $e',
        ),
      );
      return null;
    }
  }

  Future<String?> _findEventByICalUid(String idempotencyKey) async {
    final token = _cachedAccessToken;
    if (token == null) return null;

    final calendarId = Uri.encodeComponent(_selectedCalendarId);
    final iCalUid = Uri.encodeQueryComponent(
      '$idempotencyKey@fithost.amitrana.tech',
    );
    final response = await _client.get(
      Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events'
        '?iCalUID=$iCalUid&showDeleted=false&maxResults=1',
      ),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.acceptHeader: 'application/json',
      },
    );
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) return null;
    return (items.first as Map<String, dynamic>)['id'] as String?;
  }

  /// Update an existing event in Google Calendar
  Future<bool> updateEvent({
    required String googleEventId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? timeZone,
    List<int> reminderMinutesBefore = const [15],
  }) async {
    final token = _cachedAccessToken;
    if (token == null) return false;

    _updateState(
      _currentState.copyWith(status: GoogleCalendarSyncStatus.syncing),
    );

    try {
      final localTz = timeZone ?? DateTime.now().timeZoneName;
      final bodyMap = <String, dynamic>{
        'summary': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'start': {
          'dateTime': startTime.toUtc().toIso8601String(),
          'timeZone': localTz,
        },
        'end': {
          'dateTime': endTime.toUtc().toIso8601String(),
          'timeZone': localTz,
        },
        'reminders': {
          'useDefault': reminderMinutesBefore.isEmpty,
          'overrides': reminderMinutesBefore
              .map((min) => {'method': 'popup', 'minutes': min})
              .toList(),
        },
      };

      final calendarId = Uri.encodeComponent(_selectedCalendarId);
      final eventId = Uri.encodeComponent(googleEventId);
      final response = await _client.patch(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events/$eventId',
        ),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      final success = response.statusCode == 200;
      _updateState(
        _currentState.copyWith(
          status: GoogleCalendarSyncStatus.connected,
          lastSyncedAt: success ? DateTime.now() : _currentState.lastSyncedAt,
          lastError: success
              ? null
              : 'Update error ${response.statusCode}: ${response.body}',
        ),
      );
      return success;
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: GoogleCalendarSyncStatus.connected,
          lastError: 'Event update failed: $e',
        ),
      );
      return false;
    }
  }

  /// Delete an event from Google Calendar
  Future<bool> deleteEvent(String googleEventId) async {
    final token = _cachedAccessToken;
    if (token == null) return false;

    try {
      final calendarId = Uri.encodeComponent(_selectedCalendarId);
      final eventId = Uri.encodeComponent(googleEventId);
      final response = await _client.delete(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events/$eventId',
        ),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.acceptHeader: 'application/json',
        },
      );

      return response.statusCode == 204 ||
          response.statusCode == 200 ||
          response.statusCode == 404;
    } catch (e) {
      debugPrint('[GoogleCalendarService] deleteEvent error: $e');
      return false;
    }
  }

  void dispose() {
    _stateController.close();
  }
}

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final service = GoogleCalendarService();
  ref.onDispose(() => service.dispose());
  return service;
});

final googleCalendarStateProvider = StreamProvider<GoogleCalendarState>((ref) {
  final service = ref.watch(googleCalendarServiceProvider);
  return service.stateStream;
});
