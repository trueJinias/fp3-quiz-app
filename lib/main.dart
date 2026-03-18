import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'screens/tutorial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // MobileAds and Notifications are only for Mobile (Android/iOS)
  // We check kIsWeb first to avoid dart:io usage on web
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      MobileAds.instance.initialize();
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.scheduleDailyReminder();
    } catch (e) {
      debugPrint('Failed to initialize mobile services: $e');
    }
  }
  
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  runApp(
    ProviderScope(
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 既存ユーザー（チュートリアル完了済み）のみ許可ダイアログを表示
      // 新規ユーザーはチュートリアル終了時に tutorial_screen.dart 内で要求する
      if (!kIsWeb && Platform.isAndroid && !widget.isFirstLaunch) {
        await NotificationService().requestPermission();
      }
    });
    _rescheduleNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリがフォアグラウンドに戻った時に通知を再スケジュール
    // これにより端末再起動後などでも通知が復元される
    if (state == AppLifecycleState.resumed) {
      _rescheduleNotifications();
    }
  }

  /// 通知を再スケジュール（端末再起動後の復元など）
  Future<void> _rescheduleNotifications() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final notificationService = NotificationService();
        await notificationService.scheduleDailyReminder();
      } catch (e) {
        debugPrint('Failed to reschedule notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'FP3級 一問一答', // Generic Title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData(brightness: Brightness.light).textTheme),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: child!,
        );
      },
      home: widget.isFirstLaunch ? const TutorialScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
