import 'package:flutter/services.dart';
import '../../app/router.dart';
import '../../features/document_viewer/presentation/document_viewer_screen.dart';

/// Service that listens to incoming native Android ACTION_VIEW intents
/// when a user chooses "Open with MyDay" on a PDF, image, or text file.
class ExternalDocumentService {
  static const MethodChannel _channel = MethodChannel('com.myday.app/document_viewer');
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDocumentOpened') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          _navigateToDocument(args);
        }
      }
    });

    // Check cold-start intent after router is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkInitialDocument();
    });
  }

  static Future<void> _checkInitialDocument() async {
    try {
      final res = await _channel.invokeMapMethod<String, String>('getInitialDocument');
      if (res != null) {
        _navigateToDocument(res);
      }
    } catch (_) {}
  }

  static void _navigateToDocument(Map<dynamic, dynamic> map) {
    final filePath = map['filePath'] as String?;
    final fileName = map['fileName'] as String? ?? 'Document';
    final mimeType = map['mimeType'] as String?;

    if (filePath != null && filePath.isNotEmpty) {
      appRouter.push(
        '/document-viewer',
        extra: DocumentViewerArgs(
          filePath: filePath,
          fileName: fileName,
          mimeType: mimeType,
          isExternal: true,
        ),
      );
    }
  }
}
