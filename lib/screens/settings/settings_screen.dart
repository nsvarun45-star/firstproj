// lib/screens/settings/settings_screen.dart
//
// The "Settings" tab: dropdown to configure max safe wear duration
// (8/10/12 hr), a slider/input for the turbidity contamination threshold
// (default 1500), and a light/dark/system theme mode selector.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return AnimatedBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: settingsAsync.when(
                data: (settings) => _SettingsBody(settings: settings),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Failed to load settings: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;

  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, Icons.timer_outlined, 'Maximum Wear Duration'),
              const SizedBox(height: 12),
              Text(
                'Configure the safe wearing duration before LensGuard alerts you.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: settings.maxWearHours,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cyan.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: AppSettings.allowedMaxWearHours
                    .map((h) => DropdownMenuItem(value: h, child: Text('$h hours')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) notifier.updateMaxWearHours(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, Icons.water_drop_outlined, 'Turbidity Threshold'),
              const SizedBox(height: 12),
              Text(
                'Solution is flagged contaminated when turbidity drops below this value.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: settings.turbidityThreshold.toDouble(),
                      min: 800,
                      max: 2200,
                      divisions: 28,
                      activeColor: AppColors.cyan,
                      label: '${settings.turbidityThreshold}',
                      onChanged: (value) => notifier.updateTurbidityThreshold(value.round()),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${settings.turbidityThreshold}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.cyan),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, Icons.dark_mode_outlined, 'Appearance'),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Auto')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) => notifier.updateThemeMode(selection.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, Icons.info_outline_rounded, 'About'),
              const SizedBox(height: 12),
              Text(
                'LensGuard v1.0.0\nSmart Contact Lens Cleaning Case Companion App\n\n'
                'BLE data is currently MOCKED for demonstration. Connect to a real '
                'ESP32 by replacing MockBleSimulator in lib/services/ble_service.dart.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
