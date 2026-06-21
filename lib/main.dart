// lib/main.dart
//
// App entry point. Initializes the NotificationService (must happen
// before any notifications can be shown), wraps the app in a
// ProviderScope for Riverpod, and builds the MaterialApp using the
// LensGuard light/dark themes driven by the persisted ThemeMode setting.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const ProviderScope(child: LensGuardApp()));
}

class LensGuardApp extends ConsumerWidget {
  const LensGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (s) => s.themeMode,
      orElse: () => ThemeMode.system,
    );

    return MaterialApp(
      title: 'LensGuard',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const RootShell(),
    );
  }
}
