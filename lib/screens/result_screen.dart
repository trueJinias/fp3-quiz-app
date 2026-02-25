import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
import '../widgets/ad_banner.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final totalQuestions = quizState.questions.length;
    final score = quizState.score;
    final percentage = totalQuestions > 0 ? (score / totalQuestions * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
        appBar: AppBar(
          title: const Text('結果発表'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'あなたのスコア',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$score / $totalQuestions',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '正解率: $percentage%',
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(quizProvider.notifier).resetQuiz();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('ホームに戻る'),
                    ),
                  ],
                ),
              ),
            ),
            const AdBanner(),
          ],
        ),
    );
  }
}
