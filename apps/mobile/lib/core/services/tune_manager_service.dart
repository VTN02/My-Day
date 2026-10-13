import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Audio Tune model representing catalog tunes.
class ReminderTuneItem {
  final String id;
  final String name;
  final String? description;
  final String downloadUrl;
  final bool isDefault;
  final bool isLocal;
  final bool isCached;
  final String? localPath;

  const ReminderTuneItem({
    required this.id,
    required this.name,
    this.description,
    required this.downloadUrl,
    this.isDefault = false,
    this.isLocal = false,
    this.isCached = false,
    this.localPath,
  });

  ReminderTuneItem copyWith({
    String? id,
    String? name,
    String? description,
    String? downloadUrl,
    bool? isDefault,
    bool? isLocal,
    bool? isCached,
    String? localPath,
  }) {
    return ReminderTuneItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isDefault: isDefault ?? this.isDefault,
      isLocal: isLocal ?? this.isLocal,
      isCached: isCached ?? this.isCached,
      localPath: localPath ?? this.localPath,
    );
  }
}

/// Service managing the reminder tunes catalog, offline caching, audio preview, and Android notification channels.
class TuneManagerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  // Bundled offline fallback tunes
  static const List<ReminderTuneItem> bundledTunes = [
    ReminderTuneItem(
      id: 'tune_system_default',
      name: 'System Default Chime',
      description: 'Standard Android device notification alert',
      downloadUrl: '',
      isDefault: true,
      isLocal: true,
      isCached: true,
    ),
    ReminderTuneItem(
      id: 'tune_gentle_bell',
      name: 'Gentle Amber Bell',
      description: 'Soft harmonic chime designed for calm task alerts',
      downloadUrl: '',
      isDefault: false,
      isLocal: true,
      isCached: true,
    ),
    ReminderTuneItem(
      id: 'tune_focus_pulse',
      name: 'Focus Pulse',
      description: 'Energetic acoustic alert for high-priority items',
      downloadUrl: '',
      isDefault: false,
      isLocal: true,
      isCached: true,
    ),
  ];

  String? get currentlyPlayingId => _currentlyPlayingId;

  /// Fetches published tunes from Supabase if online, combining them with bundled offline tunes.
  Future<List<ReminderTuneItem>> getAvailableTunes() async {
    final tunes = List<ReminderTuneItem>.from(bundledTunes);
    final cacheDir = await _getTunesDirectory();

    try {
      // Direct REST query to Supabase reminder_tunes table
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      // Using the configured Supabase Project URL or localhost
      const supabaseUrl = 'https://admin.myday.app';
      final request = await client.getUrl(
        Uri.parse('$supabaseUrl/api/reminder-tunes'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final remoteList = json['tunes'] as List<dynamic>? ?? [];

        for (final item in remoteList) {
          final id = item['id'] as String;
          final name = item['name'] as String;
          final desc = item['description'] as String?;
          final url = item['download_url'] as String? ?? '';
          final isDef = item['is_default'] as bool? ?? false;

          final cachedFile = File('${cacheDir.path}/$id.mp3');
          final exists = await cachedFile.exists();

          tunes.add(
            ReminderTuneItem(
              id: id,
              name: name,
              description: desc,
              downloadUrl: url,
              isDefault: isDef,
              isLocal: false,
              isCached: exists,
              localPath: exists ? cachedFile.path : null,
            ),
          );
        }
      }
    } catch (_) {
      // Offline fallback: check if any previously cached remote tunes exist
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync().whereType<File>();
        for (final file in files) {
          final filename = file.path.split(Platform.pathSeparator).last;
          if (filename.endsWith('.mp3')) {
            final id = filename.replaceAll('.mp3', '');
            if (!tunes.any((t) => t.id == id)) {
              tunes.add(
                ReminderTuneItem(
                  id: id,
                  name: 'Custom Melody ($id)',
                  downloadUrl: '',
                  isLocal: false,
                  isCached: true,
                  localPath: file.path,
                ),
              );
            }
          }
        }
      }
    }

    return tunes;
  }

  /// Downloads and caches a remote tune file for offline playback.
  Future<String> downloadAndCacheTune(ReminderTuneItem tune) async {
    if (tune.isLocal || tune.downloadUrl.isEmpty) {
      return '';
    }

    final cacheDir = await _getTunesDirectory();
    final targetFile = File('${cacheDir.path}/${tune.id}.mp3');

    if (await targetFile.exists()) {
      return targetFile.path;
    }

    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(tune.downloadUrl));
    final response = await request.close();

    if (response.statusCode == 200) {
      final bytes = await response.fold<List<int>>(
        [],
        (buffer, data) => buffer..addAll(data),
      );
      await targetFile.writeAsBytes(bytes);
      return targetFile.path;
    } else {
      throw Exception('Failed to download tune: HTTP ${response.statusCode}');
    }
  }

  /// Plays audio preview of a tune.
  Future<void> playPreview(
    ReminderTuneItem tune, {
    VoidCallback? onComplete,
  }) async {
    if (_currentlyPlayingId == tune.id) {
      await stopPreview();
      return;
    }

    await stopPreview();
    _currentlyPlayingId = tune.id;

    _audioPlayer.onPlayerComplete.listen((_) {
      _currentlyPlayingId = null;
      if (onComplete != null) onComplete();
    });

    if (tune.localPath != null && await File(tune.localPath!).exists()) {
      await _audioPlayer.play(DeviceFileSource(tune.localPath!));
    } else if (tune.downloadUrl.isNotEmpty) {
      await _audioPlayer.play(UrlSource(tune.downloadUrl));
    } else {
      // Bundled local sound preview simulated tone
      _currentlyPlayingId = null;
      if (onComplete != null) onComplete();
    }
  }

  /// Stops any playing audio preview.
  Future<void> stopPreview() async {
    await _audioPlayer.stop();
    _currentlyPlayingId = null;
  }

  /// Generates or registers a dedicated Android notification channel for the selected tune.
  Future<String> ensureNotificationChannelForTune({
    required String? tuneId,
    required FlutterLocalNotificationsPlugin plugin,
  }) async {
    final androidImpl = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return 'myday_tasks_channel';

    final safeTuneId = (tuneId == null || tuneId.isEmpty)
        ? 'tune_system_default'
        : tuneId;

    final channelId = 'myday_task_channel_$safeTuneId';

    // Register channel with high importance
    final channel = AndroidNotificationChannel(
      channelId,
      'Task Reminders ($safeTuneId)',
      description: 'Notifications for tasks using reminder melody $safeTuneId',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidImpl.createNotificationChannel(channel);
    return channelId;
  }

  Future<Directory> _getTunesDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/reminder_tunes');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

final tuneManagerServiceProvider = Provider<TuneManagerService>((ref) {
  final service = TuneManagerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final availableTunesProvider = FutureProvider<List<ReminderTuneItem>>((ref) {
  return ref.watch(tuneManagerServiceProvider).getAvailableTunes();
});
