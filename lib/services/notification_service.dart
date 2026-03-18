import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'review_service.dart';

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
      // flutter_local_notifications が使用するすべてのキャッシュキーを削除
      await prefs.remove('scheduled_notifications');
      await prefs.remove('flutter_notification_plugin_cache');
      await prefs.remove('flutter_local_notifications_plugin_cache');
      await prefs.remove('repeat_notification_ids');
      await prefs.remove('scheduledNotificationIds');
      
      // Androidの場合、追加のクリーンアップ
      if (Platform.isAndroid) {
        await prefs.remove('android_notification_cache');
      }
    } catch (_) {}
  }
  
  /// 通知プラグインを安全に初期化する（キャッシュ破損対策）
  Future<void> _safeInitialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print('NotificationService: 初期化エラー、キャッシュをクリア: $e');
      await _clearNotificationCache();
      // 再試行
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    }
  }

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        final String timeZoneName = timeZoneInfo.identifier;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        tz.setLocalLocation(tz.UTC);
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _safeInitialize();

      // 起動時に古い通知キャッシュを安全にクリア（フォーマット不一致による破損対策）
      try {
        // まず既存の通知をキャンセル
        await flutterLocalNotificationsPlugin.cancelAll();
      } catch (e) {
        print('NotificationService: キャッシュ破損検出、クリアします: $e');
        await _clearNotificationCache();
        // 再初期化
        await _safeInitialize();
      }
      
      // 確実にキャッシュをクリア
      await _clearNotificationCache();
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

  /// 復習待ちの問題数に基づいた通知メッセージを生成
  String _buildNotificationMessage(int dueCount) {
    if (dueCount <= 0) {
      return '今日もお疲れ様でした！復習はバッチリです。';
    } else if (dueCount == 1) {
      return 'あと1問復習待ちがあります！スッキリ終わらせてから寝ませんか？';
    } else {
      return 'あと${dueCount}問復習待ちがあります！スッキリ終わらせてから寝ませんか？';
    }
  }

  /// 毎日21時に復習リマインダーをスケジュール（inexact: 審査対策）
  Future<void> scheduleDailyReminder() async {
    try {
      // 現在の復習待ち数を取得
      final reviewService = ReviewService();
      final dueIds = await reviewService.getDueQuestionIds();
      final dueCount = dueIds.length;
      
      final message = _buildNotificationMessage(dueCount);
      
      // 次の21時を計算
      final scheduledDate = _nextInstance(21, 0);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // ID
        '学習の時間です',
        message,
        scheduledDate, // 21:00
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: '復習待ちの問題がある場合に21時に通知します',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        // inexact: 正確な時刻ではなく、バッテリー最適化を考慮した時刻に通知
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // matchDateTimeComponents は削除: inexactAllowWhileIdle との組み合わせでは
        // Android 12+ で自動再スケジュールが信頼性低く機能しないため、
        // アプリ起動時に main.dart のライフサイクルオブザーバーが再スケジュールする
      );

      print('NotificationService: 通知をスケジュールしました - ${scheduledDate.toString()} - 復習待ち: $dueCount問');
    } catch (e) {
      print('Schedule error: $e');
    }
  }

  /// 今日の学習完了時に呼び出す。通知を明日21時にリスケジュール。
  Future<void> completeForToday() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(0);
    } catch (e) {
      print('Notification cancel error (non-critical): $e');
      await _clearNotificationCache();
    }

    // 明日以降にリスケジュール（21:00）
    try {
      // 現在の復習待ち数を取得
      final reviewService = ReviewService();
      final dueIds = await reviewService.getDueQuestionIds();
      final dueCount = dueIds.length;
      
      final message = _buildNotificationMessage(dueCount);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        '学習の時間です',
        message,
        _nextInstance(21, 0, forceTomorrow: true),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Reminder',
            channelDescription: '復習待ちの問題がある場合に21時に通知します',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        // inexact: 正確な時刻ではなく、バッテリー最適化を考慮した時刻に通知
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('NotificationService: 通知を明日21時にリスケジュール - 復習待ち: $dueCount問');
    } catch (e) {
      print('Notification reschedule error (non-critical): $e');
    }
  }

  /// 端末再起動後に通知を再スケジュールする
  Future<void> rescheduleAfterReboot() async {
    try {
      print('NotificationService: 端末再起動後の通知再スケジュールを実行');
      await scheduleDailyReminder();
    } catch (e) {
      print('NotificationService: 再起動後の再スケジュールエラー: $e');
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
