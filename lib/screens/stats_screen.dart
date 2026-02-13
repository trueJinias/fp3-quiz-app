import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final futureAsync = ref.watch(futureReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: true,
      ),
      body: statsAsync.when(
        data: (stats) {
          final learned = stats['learned'];
          final due = stats['due'];

          return futureAsync.when(
            data: (futureReviews) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCard(context, '学習済みカード', '$learned 枚', Colors.blue), // '/ 1000' removed for template safety
                  const SizedBox(height: 10),
                  _buildStatCard(context, '復習待ち', '$due 枚', Colors.orange),
                  const SizedBox(height: 30),
                  const Text('今後7日間の復習予定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        final count = futureReviews[index];
                        final height = (count / 20 * 150).clamp(10.0, 150.0);
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$count'),
                            const SizedBox(height: 5),
                            Container(
                              width: 20,
                              height: height,
                              color: Colors.blue.defaultShade(index * 100 + 200),
                            ),
                            const SizedBox(height: 5),
                            Text('+${index + 1}日'),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on MaterialColor {
  Color defaultShade(int index) {
    return this[index] ?? this;
  }
}
