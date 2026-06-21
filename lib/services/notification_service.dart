// lib/services/notification_service.dart
//
// Wraps flutter_local_notifications to provide all alerting required by
// the spec: lens wear limit exceeded (persistent + alarm + vibration),
// cleaning completed, solution contaminated, and case left open too long.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _wearLimitChannel = AndroidNotificationDetails(
    'wear_limit_channel',
    'Lens Wear Limit Alerts',
    channelDescription: 'Alerts when lens wear exceeds the safe duration',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true, // persistent notification per spec
    autoCancel: false,
    playSound: true,
  );

  static const _cleaningChannel = AndroidNotificationDetails(
    'cleaning_channel',
    'Cleaning Updates',
    channelDescription: 'Notifies when a cleaning cycle completes',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _solutionChannel = AndroidNotificationDetails(
    'solution_channel',
    'Solution Quality Alerts',
    channelDescription: 'Alerts when the cleaning solution is contaminated',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _caseOpenChannel = AndroidNotificationDetails(
    'case_open_channel',
    'Case Open Alerts',
    channelDescription: 'Alerts when the case has been left open too long',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showWearLimitExceeded() async {
    await _plugin.show(
      1001,
      'Lens usage exceeded safe limit',
      'Remove lens immediately',
      const NotificationDetails(android: _wearLimitChannel),
    );
    Vibration.hasVibrator().then((hasVib) {
      if (hasVib == true) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      }
    });
  }

  Future<void> cancelWearLimitExceeded() async {
    await _plugin.cancel(1001);
  }

  Future<void> showCleaningComplete() async {
    await _plugin.show(
      1002,
      'Cleaning Completed',
      'Lens is ready to use',
      const NotificationDetails(android: _cleaningChannel),
    );
    Vibration.hasVibrator().then((hasVib) {
      if (hasVib == true) Vibration.vibrate(duration: 300);
    });
  }

  Future<void> showSolutionContaminated() async {
    await _plugin.show(
      1003,
      'Solution quality degraded',
      'Please replace the cleaning solution',
      const NotificationDetails(android: _solutionChannel),
    );
  }

  Future<void> showCaseLeftOpen() async {
    await _plugin.show(
      1004,
      'Case left open',
      'Case has been open for more than 2 minutes',
      const NotificationDetails(android: _caseOpenChannel),
    );
  }

  Future<void> cancelCaseLeftOpen() async {
    await _plugin.cancel(1004);
  }
}
