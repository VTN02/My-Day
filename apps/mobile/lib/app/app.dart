import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/database_providers.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Root MyDay Application Widget.
class MyDayApp extends ConsumerWidget {
  const MyDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final locale = ref.watch(appLocaleProvider).value;

    return MaterialApp.router(
      title: 'MyDay',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
