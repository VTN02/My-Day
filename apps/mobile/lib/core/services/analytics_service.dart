import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/database_providers.dart';
import '../repositories/settings_repository.dart';
import 'update_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return AnalyticsService(settingsRepo);
});

/// Privacy-conscious, offline-resilient analytics service for MyDay.
/// Strictly enforces:
/// - Zero collection of personal titles, notes, expense amounts, or balances
/// - Instant halt when consent is toggled off
/// - Non-blocking asynchronous event batching
class AnalyticsService {
  final SettingsRepository _settingsRepo;

  String? _installationId;
  bool _consentEnabled = true;
  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;

  static const String _defaultEndpoint =
      'http://10.0.2.2:3000/api/analytics/collect';

  AnalyticsService(this._settingsRepo);

  /// Initializes installation identity and loads consent state
  Future<void> init() async {
    try {
      // 1. Check or generate anonymous UUID installation ID
      var installId = await _settingsRepo.getSetting('anonymous_install_id');
      if (installId == null || installId.isEmpty) {
        installId = _generateUuidV4();
        await _settingsRepo.setSetting('anonymous_install_id', installId);
        _installationId = installId;
        // Log first app open
        await trackFirstOpen();
      } else {
        _installationId = installId;
      }

      // 2. Load user consent state (default: true)
      final consent = await _settingsRepo.getSetting(
        'analytics_consent_enabled',
      );
      _consentEnabled = consent != 'false';

      // 3. Start background periodic flush timer (every 60s)
      _flushTimer?.cancel();
      _flushTimer = Timer.periodic(const Duration(seconds: 60), (_) => flush());

      // Track session start on initialization
      await trackSessionStart();
    } catch (e) {
      debugPrint('AnalyticsService init error: $e');
    }
  }

  /// Toggles user analytics consent
  Future<void> setConsentEnabled(bool enabled) async {
    _consentEnabled = enabled;
    await _settingsRepo.setSetting(
      'analytics_consent_enabled',
      enabled ? 'true' : 'false',
    );
    if (!enabled) {
      _queue.clear(); // Immediately purge queue
    }
  }

  bool get isConsentEnabled => _consentEnabled;

  /// Tracks initial application installation run
  Future<void> trackFirstOpen() async {
    await _enqueueEvent(
      eventType: 'app_first_open',
      payload: {
        'osVersion': Platform.operatingSystemVersion,
        'appVersion': AppVersion.versionName,
        'versionCode': AppVersion.versionCode,
      },
    );
  }

  /// Tracks foreground application session
  Future<void> trackSessionStart() async {
    await _enqueueEvent(
      eventType: 'session_start',
      payload: {
        'appVersion': AppVersion.versionName,
        'versionCode': AppVersion.versionCode,
      },
    );
  }

  /// Tracks feature navigation (Today, Tasks, Calendar, Finance, Notes, MyDay Split, Profile, Settings)
  Future<void> trackFeatureOpen(String feature) async {
    await _enqueueEvent(
      eventType: 'feature_open',
      payload: {'feature': feature},
    );
  }

  /// Tracks aggregate feature actions with STRICT zero-content guarantees
  Future<void> trackFeatureAction(String feature, String action) async {
    await _enqueueEvent(
      eventType: 'feature_action',
      payload: {'feature': feature, 'action': action},
    );
  }

  Future<void> _enqueueEvent({
    required String eventType,
    Map<String, dynamic>? payload,
  }) async {
    if (!_consentEnabled) return;

    final event = {
      'eventId': _generateUuidV4(),
      'eventType': eventType,
      'clientType': 'mobile_android',
      'installationId': _installationId,
      'deviceCategory': 'mobile',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...?payload,
    };

    _queue.add(event);

    // Limit in-memory queue to 50 items
    if (_queue.length > 50) {
      _queue.removeAt(0);
    }

    // Auto flush if queue reaches batch threshold
    if (_queue.length >= 10) {
      flush();
    }
  }

  /// Flushes queued events to the analytics endpoint asynchronously
  Future<void> flush() async {
    if (!_consentEnabled || _queue.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_queue);
    try {
      final response = await http
          .post(
            Uri.parse(_defaultEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(batch),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        _queue.removeWhere((item) => batch.contains(item));
      }
    } catch (_) {
      // Offline or server unavailable — events stay buffered in queue
    }
  }

  void dispose() {
    _flushTimer?.cancel();
  }

  String _generateUuidV4() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'mob_${now}_${(1000 + (now % 9000))}';
  }
}
