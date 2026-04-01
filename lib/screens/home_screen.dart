import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';
import '../widgets/ad_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<String> _categories = [
    'ライフプランニングと資金計画',
    'リスク管理',
    '金融資産運用',
    'タックスプランニング',
    '不動産',
    '相続・事業承継',
  ];

  void _showCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'カテゴリを選択',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(quizProvider.notifier).startCategoryQuiz(cat);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuizScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    child: Text(cat, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCountAsync = ref.watch(dueQuestionCountProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FP3級 過去問精釈'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  streakAsync.when(
                    data: (streak) {
                      if (streak == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$streak',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const Text('日連続', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
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
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    child: const Text('ランダム出題 (10問)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCategorySheet(context, ref),
                    icon: const Icon(Icons.category),
                    label: const Text('カテゴリごとに出題'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              '本アプリの問題は、日本FP協会が公開している過去問題を使用しています。',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const AdBanner(),
        ],
      ),
    );
  }
}
