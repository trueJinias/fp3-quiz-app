import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';

class TutorialScreen extends StatefulWidget {
  final bool fromSettings;
  const TutorialScreen({super.key, this.fromSettings = false});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _onIntroEnd(context) async {
    // 1. Request Notification Permission (only on first launch)
    if (!widget.fromSettings) {
      final granted = await NotificationService().requestPermission();
      if (!granted && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('通知が無効です'),
            content: const Text(
              '学習リマインダーを受け取るには、通知を許可してください。\n\n'
              '設定 → アプリ → FP3級 過去問精釈 → 通知 → 許可',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // 2. Save "seen tutorial" flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    // 3. Navigate back or to MainScreen
    if (context.mounted) {
      if (widget.fromSettings) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  Widget _buildDemoButton(String timeLabel, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(timeLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      allowImplicitScrolling: true,
      autoScrollDuration: null,
      infiniteAutoScroll: false,
      safeAreaList: [true, true, true, true, true],
      pages: [
        PageViewModel(
          title: "学習アプリへようこそ",
          body: "忘却曲線に基づいた効率的な学習で、\n効率よく記憶を定着させましょう。",
          image: const Icon(Icons.school, size: 100.0, color: Colors.blue),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontSize: 18.0),
          ),
        ),
        // ── NEW: 間隔反復の仕組み ──────────────────────────────────────
        PageViewModel(
          title: "間隔反復で効率よく記憶",
          image: const Icon(Icons.timeline, size: 56.0, color: Colors.teal),
          bodyWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '正解するたびに復習間隔が自動的に伸びていきます',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, height: 1.5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 155,
                child: CustomPaint(
                  painter: _ReviewIntervalPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  // ignore: deprecated_member_use
                  border: Border.all(color: Colors.teal.withOpacity(0.4)),
                ),
                child: const Text(
                  '最適なタイミングで復習することで\n短い学習時間でも確実に長期記憶へ定着！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.0, height: 1.5, color: Colors.teal),
                ),
              ),
            ],
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            contentMargin: EdgeInsets.symmetric(horizontal: 16),
            bodyPadding: EdgeInsets.zero,
            imagePadding: EdgeInsets.only(top: 8, bottom: 4),
          ),
        ),
        // ─────────────────────────────────────────────────────────────
        PageViewModel(
          title: "評価ボタンの使い方",
          image: const Icon(Icons.touch_app, size: 64.0, color: Colors.purple),
          bodyWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "回答後、次の復習タイミングを選ぶボタンが表示されます。\n「次いつ復習する？」という問いに答える感覚でボタンをタップすると\n次の問題へ進みます。",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, height: 1.6),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Text('✅ 正解した場合', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDemoButton('3日後', Colors.blue),
                        const SizedBox(width: 20),
                        _buildDemoButton('7日後', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  children: [
                    const Text('❌ 不正解の場合', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDemoButton('今日', Colors.red),
                        const SizedBox(width: 20),
                        _buildDemoButton('明日', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '「今日」ボタンはこのセッション中に再度出題されます',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            contentMargin: EdgeInsets.symmetric(horizontal: 16),
            bodyPadding: EdgeInsets.zero,
            imagePadding: EdgeInsets.only(top: 8, bottom: 4),
          ),
        ),
        PageViewModel(
          title: "毎日のノルマを達成",
          body: "1日あたりの学習枚数を設定し、\n無理なく継続できます。",
          image: const Icon(Icons.trending_up, size: 100.0, color: Colors.green),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontSize: 18.0),
          ),
        ),
        PageViewModel(
          title: "学習リマインダー",
          image: const Icon(Icons.notifications_active, size: 80.0, color: Colors.orange),
          bodyWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '「通知」をオンにすると、\n毎日のノルマがまだ終わっていない時だけ\n夜9時にお知らせします。\n\nサボり防止に役立ちます！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.0, height: 1.6),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  // ignore: deprecated_member_use
                  border: Border.all(color: Colors.amber.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.battery_alert, color: Colors.amber, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'バッテリー最適化に注意',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'このアプリのバッテリー最適化がオンになっていると、通知が届かないことがあります。\n\n'
                      '通知を確実に受け取るには：\n'
                      '設定 → アプリ → FP3級 過去問精釈 → バッテリー →「制限なし」\n\n'
                      'Samsung端末の場合：\n'
                      '設定 → バッテリー → バックグラウンドの使用を制限 → FP3級 過去問精釈 → オフ',
                      style: TextStyle(fontSize: 12.0, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
            contentMargin: EdgeInsets.symmetric(horizontal: 16),
            bodyPadding: EdgeInsets.zero,
            imagePadding: EdgeInsets.only(top: 8, bottom: 8),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: const Icon(Icons.arrow_back),
      skip: const Text('スキップ', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('開始する', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: const Color(0xFFBDBDBD),
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}

/// Draws a bar chart illustrating exponentially growing review intervals.
class _ReviewIntervalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const intervals = [1, 3, 7, 14, 30];
    const dayLabels = ['1日', '3日', '7日', '14日', '30日+'];
    const reviewLabels = ['1回目', '2回目', '3回目', '4回目', '5回目'];
    const n = 5;
    const maxInterval = 30.0;

    // Layout constants
    final chartBottom = size.height - 22.0;
    const topPadding = 22.0;

    const barColors = [
      Color(0xFF1976D2),
      Color(0xFF0097A7),
      Color(0xFF00897B),
      Color(0xFF43A047),
      Color(0xFF66BB6A),
    ];

    final barSpacing = size.width / n;
    final barWidth = barSpacing * 0.52;

    // ── Draw bars ────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final barHeight = (intervals[i] / maxInterval) * (chartBottom - topPadding);
      final centerX = barSpacing * i + barSpacing / 2;
      final left = centerX - barWidth / 2;
      final top = chartBottom - barHeight;

      final paint = Paint()
        ..color = barColors[i]
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          const Radius.circular(5),
        ),
        paint,
      );

      _drawCenteredText(
        canvas,
        dayLabels[i],
        centerX,
        top - 18,
        TextStyle(color: barColors[i], fontSize: 11, fontWeight: FontWeight.bold),
      );

      _drawCenteredText(
        canvas,
        reviewLabels[i],
        centerX,
        chartBottom + 4,
        const TextStyle(color: Color(0xFF757575), fontSize: 9),
      );
    }

    // ── Baseline ─────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, chartBottom),
      Offset(size.width, chartBottom),
      linePaint,
    );

    // ── Smooth exponential curve through bar tops ─────────────────────
    final path = Path();
    for (int i = 0; i < n; i++) {
      final barHeight = (intervals[i] / maxInterval) * (chartBottom - topPadding);
      final centerX = barSpacing * i + barSpacing / 2;
      final topY = chartBottom - barHeight;

      if (i == 0) {
        path.moveTo(centerX, topY);
      } else {
        final prevBarHeight = (intervals[i - 1] / maxInterval) * (chartBottom - topPadding);
        final prevCenterX = barSpacing * (i - 1) + barSpacing / 2;
        final prevTopY = chartBottom - prevBarHeight;
        path.cubicTo(
          prevCenterX + barSpacing * 0.55,
          prevTopY,
          centerX - barSpacing * 0.4,
          topY,
          centerX,
          topY,
        );
      }
    }

    final curvePaint = Paint()
      ..color = const Color(0x9000BCD4)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, curvePaint);
  }

  void _drawCenteredText(Canvas canvas, String text, double cx, double y, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 64);
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
