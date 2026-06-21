// lib/screens/root_shell.dart
//
// Top-level navigation shell: holds the bottom navigation bar (Home,
// Cleaning, History, Settings) and switches between the four main
// screens using an IndexedStack so each screen's state is preserved
// when switching tabs.

import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'cleaning/cleaning_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    CleaningScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.cleaning_services_outlined), selectedIcon: Icon(Icons.cleaning_services_rounded), label: 'Cleaning'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
