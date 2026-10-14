import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'notification_service.dart';

/// App Version constants (fallback when dynamic PackageInfo is unavailable)
class AppVersion {
  static const String versionName = '1.2.0';
  static const int versionCode = 5;
  static const String releaseDate = 'October 2026';

  /// Primary GitHub latest release endpoint for automatic release discovery:
  static const String gitHubLatestReleaseUrl =
      'https://api.github.com/repos/VTN02/My-Day/releases/latest';

  /// Default remote version check URL from the official GitHub repo:
  static const String defaultUpdateUrl =
      'https://raw.githubusercontent.com/VTN02/My-Day/main/version.json';

  /// Official WhatsApp Community Channel link for updates
  static const String whatsAppUpdateUrl =
      'https://whatsapp.com/channel/0029VbC9tOXGU3BRlJoxya3h';
}

/// Metadata model for remote APK updates
class AppUpdateInfo {
  final String latestVersion;
  final int versionCode;
  final String apkDownloadUrl;
  final String? directMirrorUrl;
  final String releaseDate;
  final List<String> releaseNotes;
  final bool isMandatory;
  final String? fileSize;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.apkDownloadUrl,
    this.directMirrorUrl,
    required this.releaseDate,
    required this.releaseNotes,
    this.isMandatory = false,
    this.fileSize,
  });

  /// Factory from raw version.json format
  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      versionCode: json['version_code'] as int? ?? 1,
      apkDownloadUrl: json['apk_download_url'] as String? ?? '',
      directMirrorUrl: json['mirror_url'] as String?,
      releaseDate: json['release_date'] as String? ?? '',
      releaseNotes:
          (json['release_notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isMandatory: json['is_mandatory'] as bool? ?? false,
      fileSize: json['file_size'] as String? ?? '28 MB',
    );
  }

  /// Factory from GitHub Releases API (/repos/{owner}/{repo}/releases/latest)
  factory AppUpdateInfo.fromGitHubRelease(Map<String, dynamic> json) {
    final rawTag = (json['tag_name'] as String? ?? '').trim();
    final cleanVersion = rawTag.replaceAll(RegExp(r'^[vV]'), '');

    int versionCode = 0;
    if (rawTag.contains('+')) {
      final parts = rawTag.split('+');
      versionCode = int.tryParse(parts.last) ?? 0;
    }
    if (versionCode == 0) {
      if (cleanVersion == '1.2.0') {
        versionCode = 5;
      } else if (cleanVersion == '1.1.1') {
        versionCode = 4;
      } else if (cleanVersion == '1.1.0') {
        versionCode = 3;
      } else if (cleanVersion == '1.0.1') {
        versionCode = 2;
      } else if (cleanVersion == '1.0.0') {
        versionCode = 1;
      } else {
        final p = cleanVersion
            .split('.')
            .map((e) => int.tryParse(e) ?? 0)
            .toList();
        versionCode =
            (p.isNotEmpty ? p[0] : 1) * 10000 +
            (p.length > 1 ? p[1] : 0) * 100 +
            (p.length > 2 ? p[2] : 0);
      }
    }

    final assets = (json['assets'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? apkAsset;
    for (final a in assets) {
      if (a is Map<String, dynamic>) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkAsset = a;
          if (name.contains('universal')) break;
        }
      }
    }

    final htmlUrl = json['html_url'] as String? ?? '';
    final apkDownloadUrl =
        apkAsset?['browser_download_url'] as String? ?? htmlUrl;

    String? fileSize;
    if (apkAsset != null && apkAsset['size'] is num) {
      final bytes = apkAsset['size'] as num;
      final mb = bytes / (1024 * 1024);
      fileSize = '${mb.toStringAsFixed(0)} MB';
    }

    String releaseDate = '';
    final publishedAt = json['published_at'] as String?;
    if (publishedAt != null) {
      try {
        final dt = DateTime.parse(publishedAt);
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        releaseDate = '${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        releaseDate = 'Recent Release';
      }
    }

    final rawBody = json['body'] as String? ?? '';
    final releaseNotes = _parseMarkdownNotes(rawBody);

    return AppUpdateInfo(
      latestVersion: cleanVersion.isEmpty ? '1.0.0' : cleanVersion,
      versionCode: versionCode,
      apkDownloadUrl: apkDownloadUrl,
      directMirrorUrl: htmlUrl.isNotEmpty
          ? htmlUrl
          : AppVersion.whatsAppUpdateUrl,
      releaseDate: releaseDate.isEmpty ? 'October 2026' : releaseDate,
      releaseNotes: releaseNotes,
      isMandatory: rawBody.toLowerCase().contains('[mandatory]'),
      fileSize: fileSize ?? '72 MB',
    );
  }

  static List<String> _parseMarkdownNotes(String body) {
    if (body.trim().isEmpty) {
      return ['Performance improvements, stability fixes, and UI refinements.'];
    }

    final lines = body.split(RegExp(r'\r?\n'));
    final notes = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('- ') ||
          line.startsWith('* ') ||
          line.startsWith('• ')) {
        var clean = line.substring(2).trim();
        clean = clean.replaceAll(RegExp(r'\*\*|\*|__|_'), '').trim();
        if (clean.isNotEmpty) {
          notes.add(clean);
        }
      }
    }

    if (notes.isEmpty) {
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isNotEmpty &&
            !line.startsWith('#') &&
            !line.startsWith('---') &&
            !line.startsWith('```')) {
          var clean = line.replaceAll(RegExp(r'\*\*|\*|__|_'), '').trim();
          if (clean.isNotEmpty) {
            notes.add(clean);
            if (notes.length >= 6) break;
          }
        }
      }
    }

    return notes.isEmpty
        ? ['Performance improvements, stability fixes, and UI refinements.']
        : notes;
  }
}

enum UpdateStatus { idle, checking, upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final String? installedVersion;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.status,
    this.updateInfo,
    this.installedVersion,
    this.errorMessage,
  });
}

class UpdateService {
  static const _installerChannel = MethodChannel('com.myday.app/installer');

  String _currentInstalledVersion = AppVersion.versionName;
  int _currentInstalledBuildCode = AppVersion.versionCode;

  String get currentInstalledVersion => _currentInstalledVersion;
  int get currentInstalledBuildCode => _currentInstalledBuildCode;

  /// Compares two Semantic Version strings (e.g. "1.1.1" vs "1.1.0").
  /// Returns:
  /// > 0 if v1 > v2
  /// < 0 if v1 < v2
  /// 0 if v1 == v2
  static int compareVersions(String v1, String v2) {
    final clean1 = v1.replaceAll(RegExp(r'[^0-9.]'), '');
    final clean2 = v2.replaceAll(RegExp(r'[^0-9.]'), '');
    final p1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = p1.length > p2.length ? p1.length : p2.length;
    for (var i = 0; i < maxLen; i++) {
      final n1 = i < p1.length ? p1[i] : 0;
      final n2 = i < p2.length ? p2[i] : 0;
      if (n1 > n2) return 1;
      if (n1 < n2) return -1;
    }
    return 0;
  }

  /// Evaluates whether remoteVersion or remoteBuildCode is strictly newer than current.
  static bool isVersionNewer({
    required String remoteVersion,
    required int remoteBuildCode,
    required String currentVersion,
    required int currentBuildCode,
  }) {
    final comp = compareVersions(remoteVersion, currentVersion);
    if (comp > 0) return true;
    if (comp < 0) return false;
    return remoteBuildCode > currentBuildCode;
  }

  /// Automatically checks for new releases:
  /// 1. Queries GitHub Releases API directly so ANY new GitHub release immediately triggers updates.
  /// 2. Seamlessly falls back to version.json if GitHub API is unreachable or rate-limited.
  /// 3. Compares semantic versioning dynamically against the installed app version.
  Future<UpdateCheckResult> checkForUpdates({
    String? customUrl,
    bool triggerNotification = false,
  }) async {
    // 1. Resolve currently installed app version dynamically from platform package manager
    String currentVersion = AppVersion.versionName;
    int currentBuildCode = AppVersion.versionCode;

    try {
      final dynamicVersion = await _installerChannel
          .invokeMapMethod<String, dynamic>('getAppVersion');
      if (dynamicVersion != null) {
        final dynName = dynamicVersion['versionName'] as String?;
        final dynCode = dynamicVersion['versionCode'] as int?;
        if (dynName != null && dynName.isNotEmpty) {
          currentVersion = dynName;
        }
        if (dynCode != null && dynCode > 0) {
          currentBuildCode = dynCode;
        }
      }
    } catch (_) {
      // Fallback to AppVersion constants
    }

    _currentInstalledVersion = currentVersion;
    _currentInstalledBuildCode = currentBuildCode;

    AppUpdateInfo? updateInfo;

    // 2. Fetch remote update information
    if (customUrl != null) {
      updateInfo = await _fetchFromUrl(customUrl);
    } else {
      // Query both GitHub Releases API and raw version.json concurrently for maximum reliability
      final ghFuture = _fetchFromGitHubRelease();
      final jsonFuture = _fetchFromVersionJson();

      final results = await Future.wait([ghFuture, jsonFuture]);
      final ghInfo = results[0];
      final jsonInfo = results[1];

      if (ghInfo != null && jsonInfo != null) {
        final comp = compareVersions(
          ghInfo.latestVersion,
          jsonInfo.latestVersion,
        );
        if (comp > 0) {
          updateInfo = ghInfo;
        } else if (comp < 0) {
          updateInfo = jsonInfo;
        } else {
          updateInfo = ghInfo.versionCode >= jsonInfo.versionCode
              ? ghInfo
              : jsonInfo;
        }
      } else {
        updateInfo = ghInfo ?? jsonInfo;
      }
    }

    if (updateInfo == null) {
      return UpdateCheckResult(
        status: UpdateStatus.error,
        installedVersion: currentVersion,
        errorMessage:
            'Unable to check for updates. Please check your internet connection.',
      );
    }

    // 3. Compare with installed version
    final isNewer = isVersionNewer(
      remoteVersion: updateInfo.latestVersion,
      remoteBuildCode: updateInfo.versionCode,
      currentVersion: currentVersion,
      currentBuildCode: currentBuildCode,
    );

    if (isNewer) {
      // Trigger system notification to lock screen and status bar only when requested
      if (triggerNotification) {
        try {
          NotificationService().showAppUpdateNotification(
            latestVersion: updateInfo.latestVersion,
            fileSize: updateInfo.fileSize,
            releaseNotes: updateInfo.releaseNotes,
          );
        } catch (_) {}
      }

      return UpdateCheckResult(
        status: UpdateStatus.updateAvailable,
        updateInfo: updateInfo,
        installedVersion: currentVersion,
      );
    } else {
      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        installedVersion: currentVersion,
      );
    }
  }

  Future<AppUpdateInfo?> _fetchFromGitHubRelease() async {
    try {
      final uri = Uri.parse(AppVersion.gitHubLatestReleaseUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 7);

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'MyDay-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return AppUpdateInfo.fromGitHubRelease(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AppUpdateInfo?> _fetchFromVersionJson([String? url]) async {
    try {
      final uri = Uri.parse(url ?? AppVersion.defaultUpdateUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 7);

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'MyDay-App');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AppUpdateInfo?> _fetchFromUrl(String url) async {
    if (url.contains('api.github.com')) {
      return _fetchFromGitHubRelease();
    }
    return _fetchFromVersionJson(url);
  }

  /// Downloads the APK directly inside the app with byte-level progress,
  /// and directly launches Android's native installer dialog without opening any browser.
  /// Checks whether Android has granted permission to install unknown apps
  static Future<bool> canInstallUnknownPackages() async {
    try {
      final allowed = await _installerChannel.invokeMethod<bool>(
        'canInstallUnknownPackages',
      );
      return allowed ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system Unknown App Sources settings screen for MyDay
  static Future<void> openInstallPermissionSettings() async {
    try {
      await _installerChannel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  /// Directly requests Android PackageInstaller to install an APK file
  static Future<bool> triggerNativeInstall(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final success = await _installerChannel.invokeMethod<bool>('installApk', {
        'filePath': file.path,
      });
      return success == true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a downloaded APK already exists in cache and is valid
  static Future<File?> getExistingDownloadedApk() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/myday_update.apk');
      if (await file.exists() && (await file.length()) > 5 * 1024 * 1024) {
        return file;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Downloads the APK directly inside the app with byte-level progress,
  /// automatic chunk resume across network drops (Range requests),
  /// and triggers Android's native installer dialog.
  static Future<void> downloadAndInstallApk({
    required String apkUrl,
    required void Function(double progress, int receivedBytes, int totalBytes)
    onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/myday_update.apk.tmp');
    final finalFile = File('${tempDir.path}/myday_update.apk');

    int totalBytes = -1;
    int receivedBytes = 0;

    if (await tempFile.exists()) {
      receivedBytes = await tempFile.length();
    }

    int retryCount = 0;
    const maxRetries = 5;

    while (retryCount < maxRetries) {
      HttpClient? client;
      IOSink? sink;
      try {
        client = HttpClient()
          ..autoUncompress = false
          ..connectionTimeout = const Duration(seconds: 25)
          ..idleTimeout = const Duration(seconds: 45);

        // Resolve redirects
        var currentUri = Uri.parse(apkUrl);
        HttpClientResponse? response;
        int redirectCount = 0;

        while (redirectCount < 6) {
          final request = await client.getUrl(currentUri);
          request.headers.set('User-Agent', 'MyDay-App');
          request.headers.set('Connection', 'keep-alive');
          request.headers.set('Accept-Encoding', 'identity');
          request.followRedirects = false;

          // Request range if we already have partial data
          if (receivedBytes > 0 && redirectCount == 0) {
            request.headers.set(
              HttpHeaders.rangeHeader,
              'bytes=$receivedBytes-',
            );
          }

          response = await request.close();

          if (response.isRedirect) {
            final location = response.headers.value(HttpHeaders.locationHeader);
            if (location == null) {
              throw Exception('Received redirect without Location header');
            }
            currentUri = Uri.parse(location);
            redirectCount++;
          } else {
            break;
          }
        }

        if (response == null) {
          throw Exception('Unable to establish connection to update server.');
        }

        // If server accepted range (206 Partial Content)
        if (response.statusCode == 206) {
          final contentRange = response.headers.value(
            HttpHeaders.contentRangeHeader,
          );
          if (contentRange != null && contentRange.contains('/')) {
            final fullLength = int.tryParse(contentRange.split('/').last);
            if (fullLength != null && fullLength > 0) {
              totalBytes = fullLength;
            }
          }
          if (totalBytes <= 0 && response.contentLength > 0) {
            totalBytes = receivedBytes + response.contentLength;
          }
          sink = tempFile.openWrite(mode: FileMode.append);
        } else if (response.statusCode == 200) {
          // Full file download
          receivedBytes = 0;
          totalBytes = response.contentLength;
          sink = tempFile.openWrite(mode: FileMode.write);
        } else if (response.statusCode == 416) {
          // Range Not Satisfiable: file might already be complete
          if (receivedBytes > 10 * 1024 * 1024) {
            break;
          } else {
            receivedBytes = 0;
            if (await tempFile.exists()) await tempFile.delete();
            retryCount++;
            continue;
          }
        } else {
          throw Exception(
            'Download server returned HTTP ${response.statusCode}',
          );
        }

        await for (final chunk in response) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          final progress = totalBytes > 0
              ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;
          onProgress(progress, receivedBytes, totalBytes);
        }

        await sink.flush();
        await sink.close();
        sink = null;
        client.close();
        client = null;

        // Verify download finished if totalBytes was known
        if (totalBytes > 0 && receivedBytes < totalBytes) {
          throw HttpException(
            'Connection closed prematurely ($receivedBytes of $totalBytes bytes)',
          );
        }

        break; // Successfully finished
      } catch (e) {
        try {
          await sink?.flush();
          await sink?.close();
        } catch (_) {}
        try {
          client?.close(force: true);
        } catch (_) {}

        retryCount++;
        if (await tempFile.exists()) {
          receivedBytes = await tempFile.length();
        }

        if (retryCount >= maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: 900 * retryCount));
      }
    }

    if (await tempFile.exists() &&
        (await tempFile.length()) > 5 * 1024 * 1024) {
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);
    } else {
      throw Exception('Downloaded update is incomplete or corrupted.');
    }

    // Trigger Native Android Package Installer
    final installed = await triggerNativeInstall(finalFile.path);
    if (!installed) {
      final canInstall = await canInstallUnknownPackages();
      if (!canInstall) {
        await openInstallPermissionSettings();
        throw Exception(
          'Please allow "Install unknown apps" for MyDay in Settings, then tap Install.',
        );
      }
    }
  }

  /// Opens the WhatsApp Community Channel directly in WhatsApp app or browser.
  static Future<bool> openWhatsAppCommunity() async {
    final uri = Uri.parse(AppVersion.whatsAppUpdateUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (_) {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  /// Shows the Update Available bottom sheet
  static void showUpdateSheet({
    required BuildContext context,
    required AppUpdateInfo info,
    String? installedVersion,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !info.isMandatory,
      enableDrag: !info.isMandatory,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _UpdateModalContent(info: info, installedVersion: installedVersion),
    );
  }
}

class _UpdateModalContent extends StatefulWidget {
  final AppUpdateInfo info;
  final String? installedVersion;

  const _UpdateModalContent({required this.info, this.installedVersion});

  @override
  State<_UpdateModalContent> createState() => _UpdateModalContentState();
}

class _UpdateModalContentState extends State<_UpdateModalContent> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingApk();
  }

  Future<void> _checkExistingApk() async {
    final existing = await UpdateService.getExistingDownloadedApk();
    if (existing != null && mounted) {
      setState(() {
        _isDownloaded = true;
        _progress = 1.0;
        _statusText = 'Update package ready to install.';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _handleInstallAction() async {
    if (_isDownloaded) {
      final existing = await UpdateService.getExistingDownloadedApk();
      if (existing != null) {
        setState(() {
          _statusText = 'Opening Android installer...';
          _errorMessage = null;
        });
        final installed = await UpdateService.triggerNativeInstall(
          existing.path,
        );
        if (!installed) {
          final canInstall = await UpdateService.canInstallUnknownPackages();
          if (!canInstall) {
            await UpdateService.openInstallPermissionSettings();
            if (mounted) {
              setState(() {
                _errorMessage =
                    'Please enable "Allow from this source" in Settings, then tap Install.';
              });
            }
            return;
          }
        } else {
          return;
        }
      }
    }

    await _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _statusText = 'Starting download...';
      _progress = 0.0;
    });

    try {
      await UpdateService.downloadAndInstallApk(
        apkUrl: widget.info.apkDownloadUrl,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
              if (total > 0) {
                _statusText =
                    'Downloading update: ${(progress * 100).toInt()}% (${_formatBytes(received)} / ${_formatBytes(total)})';
              } else {
                _statusText = 'Downloading: ${_formatBytes(received)}';
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _statusText = 'Opening Android installer...';
          _progress = 1.0;
        });
      }
    } catch (e) {
      if (mounted) {
        final existing = await UpdateService.getExistingDownloadedApk();
        setState(() {
          _isDownloading = false;
          _isDownloaded = existing != null;
          _errorMessage = _formatErrorMessage(e);
        });
      }
    }
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString().replaceFirst('Exception: ', '');
    if (str.contains('Connection closed') ||
        str.contains('SocketException') ||
        str.contains('HandshakeException') ||
        str.contains('Network is unreachable')) {
      return 'Network connection was interrupted. Tap "Resume Download" to continue.';
    }
    if (str.contains('Install unknown apps') || str.contains('permission')) {
      return 'Please allow "Install unknown apps" for MyDay in Settings, then tap Install.';
    }
    if (str.contains('404')) {
      return 'Release file is currently being synced. Please try again shortly.';
    }
    return str.split(', uri =').first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.darkCardSurface
        : AppColors.lightCardSurface;
    final primaryTextColor = isDark
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final currentDisplayVersion =
        widget.installedVersion ?? AppVersion.versionName;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: secondaryTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: AppColors.primaryIndigo,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'New Version Available',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryIndigo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${widget.info.latestVersion}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Installed: v$currentDisplayVersion • Size: ${widget.info.fileSize ?? "85 MB"}',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Scrollable Middle Section (Guarantees zero overflow on any device)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1524)
                            : const Color(0xFFF8FAFC),
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "What's New in this Update:",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (widget.info.releaseNotes.isEmpty)
                            Text(
                              '• Performance improvements and bug fixes.',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            )
                          else
                            ...widget.info.releaseNotes.map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✓  ',
                                      style: TextStyle(
                                        color: AppColors.successMint,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        note,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your data is 100% safe. Android will install the update directly on top of your current app without touching your records.',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Live In-App Download Progress Indicator
                    if (_isDownloading) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryIndigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          backgroundColor: borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryIndigo,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorCoral.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.errorCoral.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.errorCoral,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.errorCoral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Fixed Bottom Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _handleInstallAction,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isDownloaded
                                ? Icons.install_mobile_rounded
                                : (_errorMessage != null
                                      ? Icons.replay_rounded
                                      : Icons.download_rounded),
                            size: 18,
                          ),
                    label: Text(
                      _isDownloading
                          ? 'Downloading APK...'
                          : (_isDownloaded
                                ? 'Install APK Now'
                                : (_errorMessage != null
                                      ? 'Resume Download'
                                      : 'Direct Install APK')),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading
                        ? null
                        : () {
                            UpdateService.openWhatsAppCommunity();
                          },
                    icon: const Icon(
                      Icons.chat_rounded,
                      size: 16,
                      color: Color(0xFF25D366),
                    ),
                    label: const Text('Open WhatsApp Channel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                    ),
                  ),
                ),
                if (!widget.info.isMandatory && !_isDownloading) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Later',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

class AppUpdateCheckResultNotifier extends Notifier<UpdateCheckResult?> {
  @override
  UpdateCheckResult? build() => null;

  void set(UpdateCheckResult? result) {
    state = result;
  }
}

/// Shared state provider holding the latest update check result
final appUpdateCheckResultProvider =
    NotifierProvider<AppUpdateCheckResultNotifier, UpdateCheckResult?>(
      AppUpdateCheckResultNotifier.new,
    );
