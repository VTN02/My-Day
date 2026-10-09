import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// App Version constants
class AppVersion {
  static const String versionName = '1.0.0';
  static const int versionCode = 1;
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
      releaseNotes: (json['release_notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isMandatory: json['is_mandatory'] as bool? ?? false,
      fileSize: json['file_size'] as String? ?? '28 MB',
    );
  }
}

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  error,
}

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
  /// Checks remote server for the latest APK version.
  /// Compares remote [versionCode] against local [AppVersion.versionCode].
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

  /// Launches the APK download URL in the device's native browser / download manager.
  /// When download finishes, Android asks the user to install over existing app.
  static Future<bool> startApkDownload(String apkUrl) async {
    if (apkUrl.isEmpty) return false;
    final uri = Uri.parse(apkUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens the WhatsApp Community Channel to grab the latest pinned APK.
  static Future<bool> openWhatsAppCommunity() async {
    final uri = Uri.parse(AppVersion.whatsAppUpdateUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Shows the Update Available dialog/bottom sheet
  static void showUpdateSheet({
    required BuildContext context,
    required AppUpdateInfo info,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateModalContent(info: info),
    );
  }
}

class _UpdateModalContent extends StatelessWidget {
  final AppUpdateInfo info;

  const _UpdateModalContent({required this.info});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
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
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryIndigo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${info.latestVersion}',
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
                        'Installed: v${AppVersion.versionName} • Size: ${info.fileSize ?? "28 MB"}',
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
                color: isDark ? const Color(0xFF0F1524) : const Color(0xFFF8FAFC),
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
                  if (info.releaseNotes.isEmpty)
                    Text(
                      '• Performance improvements and bug fixes.',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    )
                  else
                    ...info.releaseNotes.map(
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
                  Icon(Icons.info_outline_rounded,
                      color: Colors.amber, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your data is 100% safe. Android will update the app without touching your existing tasks, habits, or money records.',
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      UpdateService.startApkDownload(info.apkDownloadUrl);
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download & Update APK'),
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
                    onPressed: () {
                      Navigator.pop(context);
                      UpdateService.openWhatsAppCommunity();
                    },
                    icon: const Icon(Icons.chat_rounded,
                        size: 16, color: Color(0xFF25D366)),
                    label: const Text('Get from WhatsApp Channel'),
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
                if (!info.isMandatory) ...[
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
