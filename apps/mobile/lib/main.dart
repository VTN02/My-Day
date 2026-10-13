import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/external_document_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Standard clean mobile layout (respects status bar and navigation bar)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  try {
    await NotificationService().initialize();
  } catch (_) {}

  // Native Android "Open with MyDay" Document Intent Listener
  ExternalDocumentService.initialize();

  runApp(const ProviderScope(child: MyDayApp()));
}
