import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 破損した通知キャッシュをSharedPreferencesから削除する
  Future<void> _clearNotificationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scheduled_notifications');
      await prefs.remove('flutter_notification_plugin_cache');
    } catch (_) {}
  }

  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // 起動時に古い通知キャッシュを安全にクリア（フォーマット不一致による破損対策）
      try {
        await flutterLocalNotificationsPlugin.cancelAll();
      } catch (e) {
        print('NotificationService: キャッシュ破損検出、クリアします: $e');
        await _clearNotificationCache();
      }
    } catch (e) {
      print('NotificationService init error: $e');
    }
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // ID
        '学習の時間です',
        '本日のノルマはまだ達成されていません。少しだけ頑張りましょう！',
        _nextInstance(9, 0), // 09:00
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: 'Reminds you to study if you haven\'t finished your quota',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time
      );
    } catch (e) {
      print('Schedule error: $e');
    }
  }

  /// 今日のノルマ達成時に呼び出す。通知を明日以降にリスケジュール。
  Future<void> completeForToday() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(0);
    } catch (e) {
      print('Notification cancel error (non-critical): $e');
      await _clearNotificationCache();
    }

    // 明日以降にリスケジュール
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        '学習の時間です',
        '本日のノルマはまだ達成されていません。少しだけ頑張りましょう！',
        _nextInstance(9, 0, forceTomorrow: true),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: 'Reminds you to study if you haven\'t finished your quota',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Notification reschedule error (non-critical): $e');
    }
  }

  tz.TZDateTime _nextInstance(int hour, int minute, {bool forceTomorrow = false}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (forceTomorrow || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
