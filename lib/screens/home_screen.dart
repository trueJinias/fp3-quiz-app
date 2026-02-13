import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';
import '../widgets/ad_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCountAsync = ref.watch(dueQuestionCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FP3級 一問一答'), // Generic Title
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'FP3級試験対策',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(quizProvider.notifier).startNormalQuiz();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QuizScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        // Explicitly set colors for better visibility
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      child: const Text('ランダム出題 (10問)'),
                    ),
                    const SizedBox(height: 20),
                    dueCountAsync.when(
                      data: (count) {
                        return ElevatedButton.icon(
                          onPressed: count > 0 ? () {
                             ref.read(quizProvider.notifier).startReviewQuiz();
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const QuizScreen()),
                             );
                          } : null,
                          icon: const Icon(Icons.refresh),
                          label: Text('今日の復習 ($count問)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange.shade900
                                : Colors.orange.shade100,
                            foregroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.brown.shade900,
                          ),
                        );
                      },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Error: $e'),
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
