import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/document_viewer/presentation/document_viewer_screen.dart';
import '../theme/app_colors.dart';

/// Centralized service for reliably opening documents and attachments in MyDay.
/// Routes internal formats (PDF, Image, Text) to the built-in DocumentViewer,
/// and routes Office formats (DOC, DOCX, XLS) to compatible external Android apps
/// with FileProvider URI permissions and graceful fallbacks.
class DocumentLauncherService {
  static const MethodChannel _channel = MethodChannel(
    'com.myday.app/document_viewer',
  );

  /// Resolves the canonical MIME type based on file extension and/or existing type.
  static String resolveMimeType(String fileName, [String? explicitType]) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf') || explicitType == 'pdf') {
      return 'application/pdf';
    }
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.txt') ||
        lower.endsWith('.log') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.md')) {
      return 'text/plain';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return explicitType ?? 'application/octet-stream';
  }

  static bool isPdf(String fileName, [String? type]) {
    final mime = resolveMimeType(fileName, type);
    return mime == 'application/pdf';
  }

  static bool isImage(String fileName, [String? type]) {
    final mime = resolveMimeType(fileName, type);
    return mime.startsWith('image/');
  }

  static bool isText(String fileName, [String? type]) {
    final mime = resolveMimeType(fileName, type);
    return mime.startsWith('text/');
  }

  static bool isOfficeDoc(String fileName, [String? type]) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx');
  }

  /// Opens a document attachment according to its type.
  static Future<void> openDocument({
    required BuildContext context,
    required String filePath,
    required String fileName,
    String? fileType,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File not found: "$fileName". It may have been moved or deleted.',
            ),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
      return;
    }

    final mimeType = resolveMimeType(fileName, fileType);

    if (!context.mounted) return;

    // 1. Internal Viewers for PDF, Image, and Text
    if (isPdf(fileName, fileType) ||
        isImage(fileName, fileType) ||
        isText(fileName, fileType)) {
      context.push(
        '/document-viewer',
        extra: DocumentViewerArgs(
          filePath: filePath,
          fileName: fileName,
          mimeType: mimeType,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    // 2. External Office Document Viewer (DOC, DOCX, XLSX, etc.)
    await openExternally(
      context: context,
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Delegates opening to a native external app via FileProvider content URI.
  static Future<void> openExternally({
    required BuildContext context,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    final resolvedMime = mimeType ?? resolveMimeType(fileName);

    try {
      // First attempt: invoke native platform channel with FileProvider & chooser
      final nativeRes = await _channel.invokeMapMethod<String, dynamic>(
        'openFile',
        {
          'filePath': filePath,
          'mimeType': resolvedMime,
          'title': 'Open $fileName',
        },
      );

      final success = nativeRes?['success'] as bool? ?? false;
      if (success) return;
    } catch (_) {
      // Fallback to open_filex if platform channel is unavailable
    }

    // Secondary attempt: open_filex with explicit MIME type
    try {
      final res = await OpenFilex.open(filePath, type: resolvedMime);
      if (res.type == ResultType.done) {
        return;
      }
    } catch (_) {}

    // If no app was found or open failed, guide the user
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warningAmber,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No Compatible App Found',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'No application on your device can open "$fileName" ($resolvedMime).\n\n'
              'Please install an app such as Google Docs, Microsoft Word, or a compatible document reader, or share this document to another device.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(filePath, name: fileName)],
                      text: fileName,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }
}
