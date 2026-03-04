import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/quiz_provider.dart';
import '../widgets/ad_banner.dart';
import 'result_screen.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);

    // Navigate to ResultScreen if completed
    if (quizState.isCompleted) {
      Future.microtask(() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      ));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quizState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (quizState.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('確認')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  quizState.errorMessage ?? '出題できる問題がありません。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = quizState.currentQuestion;

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 50.0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdBanner(),
                AppBar(
                  title: Text('問題 ${quizState.currentIndex + 1} / ${quizState.questions.length}'),
                  primary: false,
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _preprocessText(question.question),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (question.imagePath != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          question.imagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('画像が読み込めませんでした。(アセットを確認してください)'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) {
                        final options = question.options.isNotEmpty 
                            ? question.options 
                            : ['適切', '不適切'];
                            
                        return Column(
                          children: List.generate(options.length, (index) {
                            final isSelected = quizState.selectedOptionIndex == index;
                            final isCorrect = index == question.correctIndex;
                            final isAnswered = quizState.isAnswered;
        
                            Color? buttonColor;
                            if (isAnswered) {
                              if (isSelected) {
                                buttonColor = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                              } else if (isCorrect && isSelected) {
                                buttonColor = Colors.green.shade100;
                              }
                            }
        
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: OutlinedButton(
                                onPressed: isAnswered ? null : () => quizNotifier.selectOption(index),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.centerLeft,
                                  side: BorderSide(
                                    color: isAnswered && (isSelected || (isCorrect && isAnswered)) 
                                        ? (isCorrect ? Colors.green : Colors.red) 
                                        : Colors.grey,
                                  ),
                                ),
                                child: Text(
                                  '${['ア', 'イ', 'ウ', 'エ'][index < 4 ? index : index % 4]}. ${options[index]}',
                                  style: TextStyle(
                                    color: isAnswered
                                        ? (isCorrect
                                            ? Colors.green
                                            : (isSelected ? Colors.red : Theme.of(context).colorScheme.onSurface))
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }
                    ),
                    if (quizState.isAnswered) ...[
                      const SizedBox(height: 24),
                      Text(
                        'この問題、次いつ復習する？',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      if (quizState.nextIntervalLabels != null)
                         Builder(
                           builder: (context) {
                             final isCorrect = quizState.selectedOptionIndex == question.correctIndex;
                             return Row(
                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               children: [
                                 if (!isCorrect) ...[
                                   _buildRateButton(context, quizNotifier, 1, 'もう一度', Colors.red, quizState.nextIntervalLabels![1]!),
                                   _buildRateButton(context, quizNotifier, 2, '難しい', Colors.orange, quizState.nextIntervalLabels![2]!),
                                 ],
                                 if (isCorrect) ...[
                                   _buildRateButton(context, quizNotifier, 3, '正解', Colors.blue, quizState.nextIntervalLabels![3]!),
                                   _buildRateButton(context, quizNotifier, 4, '簡単', Colors.green, quizState.nextIntervalLabels![4]!),
                                 ],
                               ],
                             );
                           }
                         )
                      else 
                         const Center(child: CircularProgressIndicator()),
                      
                      const SizedBox(height: 12),
                      AdBanner(size: AdSize.mediumRectangle),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade900.withOpacity(0.5)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quizState.selectedOptionIndex == question.correctIndex ? '正解！' : '不正解...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: quizState.selectedOptionIndex == question.correctIndex
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '【解説】',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(question.explanation),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildRateButton(BuildContext context, QuizNotifier notifier, int rating, String label, Color color, String timeLabel) {
    return InkWell(
      onTap: () => notifier.rateQuestion(rating),
      child: Column(
        children: [
          Text(
            timeLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? color.withOpacity(0.15) 
                  : color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _preprocessText(String text) {
    return text.replaceAllMapped(
      RegExp(r'([^\n])・'),
      (match) => '${match.group(1)}\n\n・',
    );
  }
}
