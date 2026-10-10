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

/// App Version constants
class AppVersion {
  static const String versionName = '1.1.0';
  static const int versionCode = 3;
  static const String releaseDate = 'October 2026';

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
}

enum UpdateStatus { idle, checking, upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.status,
    this.updateInfo,
    this.errorMessage,
  });
}

class UpdateService {
  static const _installerChannel = MethodChannel('com.myday.app/installer');

  /// Checks remote server for the latest APK version.
  Future<UpdateCheckResult> checkForUpdates({String? customUrl}) async {
    final urlString = customUrl ?? AppVersion.defaultUpdateUrl;

    try {
      final uri = Uri.parse(urlString);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 7);

      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final updateInfo = AppUpdateInfo.fromJson(data);

        if (updateInfo.versionCode > AppVersion.versionCode) {
          // Trigger system notification to lock screen and status bar
          NotificationService().showAppUpdateNotification(
            latestVersion: updateInfo.latestVersion,
            fileSize: updateInfo.fileSize,
            releaseNotes: updateInfo.releaseNotes,
          );

          return UpdateCheckResult(
            status: UpdateStatus.updateAvailable,
            updateInfo: updateInfo,
          );
        } else {
          return const UpdateCheckResult(status: UpdateStatus.upToDate);
        }
      } else {
        return UpdateCheckResult(
          status: UpdateStatus.error,
          errorMessage: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } on SocketException {
      return const UpdateCheckResult(
        status: UpdateStatus.error,
        errorMessage: 'No internet connection to check for updates.',
      );
    } catch (e) {
      return UpdateCheckResult(
        status: UpdateStatus.error,
        errorMessage: 'Unable to check for updates: $e',
      );
    }
  }

  /// Downloads the APK directly inside the app with byte-level progress,
  /// and directly launches Android's native installer dialog without opening any browser.
  static Future<void> downloadAndInstallApk({
    required String apkUrl,
    required void Function(double progress, int receivedBytes, int totalBytes)
    onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/myday_update.apk');
    if (await file.exists()) {
      await file.delete();
    }

    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(apkUrl));
    final response = await request.close();

    if (response.statusCode != 200 && response.statusCode != 302) {
      throw Exception('Failed to download APK (HTTP ${response.statusCode})');
    }

    final totalBytes = response.contentLength;
    int receivedBytes = 0;

    final sink = file.openWrite();
    await for (final chunk in response) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
      onProgress(progress, receivedBytes, totalBytes);
    }
    await sink.flush();
    await sink.close();

    // Trigger Native Android Package Installer
    try {
      final success = await _installerChannel.invokeMethod<bool>('installApk', {
        'filePath': file.path,
      });
      if (success != true) {
        // Fallback: Launch intent directly via url_launcher file URI
        await launchUrl(
          Uri.file(file.path),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      await launchUrl(
        Uri.file(file.path),
        mode: LaunchMode.externalApplication,
      );
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
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !info.isMandatory,
      enableDrag: !info.isMandatory,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateModalContent(info: info),
    );
  }
}

class _UpdateModalContent extends StatefulWidget {
  final AppUpdateInfo info;

  const _UpdateModalContent({required this.info});

  @override
  State<_UpdateModalContent> createState() => _UpdateModalContentState();
}

class _UpdateModalContentState extends State<_UpdateModalContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
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
          _statusText = 'Opening Android installer...';
          _progress = 1.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download failed: $e';
        });
      }
    }
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                margin: const EdgeInsets.only(bottom: 20),
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
                        'Installed: v${AppVersion.versionName} • Size: ${widget.info.fileSize ?? "28 MB"}',
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
            const SizedBox(height: 18),
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
            const SizedBox(height: 18),

            // Live In-App Download Progress Indicator
            if (_isDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                ],
              ),
            ],

            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.errorCoral,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _startDownload,
                    icon: _isDownloading
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
                      _isDownloading
                          ? 'Downloading APK...'
                          : 'Direct Install APK',
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
