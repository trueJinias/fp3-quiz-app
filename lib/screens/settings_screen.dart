import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../services/review_service.dart';
import '../providers/quiz_provider.dart';
import '../providers/theme_provider.dart';
import '../services/payment_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _newCardsPerDay = 20;
  final _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // Init Payment
    final paymentService = PaymentService();
    paymentService.init();
    paymentService.onPurchaseSuccess = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    };
    paymentService.onPurchaseError = (message) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('エラー'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    };
  }
  
  @override
  void dispose() {
    PaymentService().onPurchaseSuccess = null;
    PaymentService().onPurchaseError = null;
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final val = await _settingsService.getNewCardsPerDay();
    setState(() {
      _newCardsPerDay = val;
    });
  }

  Future<void> _saveSettings(int value) async {
    setState(() {
      _newCardsPerDay = value;
    });
    await _settingsService.setNewCardsPerDay(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '学習設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('1日の新規カード上限'),
            subtitle: Text('$_newCardsPerDay 枚'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    int tempValue = _newCardsPerDay;
                    return AlertDialog(
                      title: const Text('1日の新規カード上限'),
                      content: StatefulBuilder(
                        builder: (context, setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$tempValue 枚'),
                              Slider(
                                value: tempValue.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 20,
                                label: tempValue.toString(),
                                onChanged: (val) {
                                  setState(() {
                                    tempValue = val.round();
                                  });
                                },
                              ),
                            ],
                          );
                        }
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                             _saveSettings(tempValue);
                             Navigator.pop(context);
                          },
                          child: const Text('保存'),
                        ),
                      ],
                    );
                  }
              );
            },
          ),
          ListTile(
            title: const Text('テーマ設定'),
            subtitle: Consumer(
              builder: (context, ref, child) {
                final mode = ref.watch(themeProvider);
                switch (mode) {
                  case ThemeMode.light:
                    return const Text('ライトモード');
                  case ThemeMode.dark:
                    return const Text('ダークモード');
                  case ThemeMode.system:
                    return const Text('端末の設定に合わせる');
                }
              },
            ),
            trailing: const Icon(Icons.brightness_6),
            onTap: () {
               showDialog(
                 context: context,
                 builder: (context) => Consumer(
                   builder: (context, ref, _) {
                     return SimpleDialog(
                       title: const Text('テーマを選択'),
                       children: [
                         RadioListTile<ThemeMode>(
                           title: const Text('端末の設定に合わせる'),
                           value: ThemeMode.system,
                           groupValue: ref.watch(themeProvider),
                           onChanged: (value) {
                             if (value != null) {
                               ref.read(themeProvider.notifier).setTheme(value);
                               Navigator.pop(context);
                             }
                           },
                         ),
                         RadioListTile<ThemeMode>(
                           title: const Text('ライトモード'),
                           value: ThemeMode.light,
                           groupValue: ref.watch(themeProvider),
                           onChanged: (value) {
                             if (value != null) {
                               ref.read(themeProvider.notifier).setTheme(value);
                               Navigator.pop(context);
                             }
                           },
                         ),
                         RadioListTile<ThemeMode>(
                           title: const Text('ダークモード'),
                           value: ThemeMode.dark,
                           groupValue: ref.watch(themeProvider),
                           onChanged: (value) {
                             if (value != null) {
                               ref.read(themeProvider.notifier).setTheme(value);
                               Navigator.pop(context);
                             }
                           },
                         ),
                       ],
                     );
                   },
                 ),
               );
            },
          ),
          const Divider(),
          const Text(
            'データ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('データの初期化'),
            subtitle: const Text('学習履歴をすべて消去します'),
            trailing: const Icon(Icons.delete, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('警告'),
                  content: const Text('本当に学習履歴を消去しますか？\nこの操作は取り消せません。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () async {
                         await ReviewService().resetAll();
                         ref.invalidate(statsProvider);
                         ref.invalidate(dueQuestionCountProvider);
                         ref.invalidate(futureReviewsProvider);
                         ref.invalidate(quizProvider);

                         if (context.mounted) {
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('学習履歴を消去しました')),
                           );
                         }
                      },
                      child: const Text('消去', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
           const Text(
            'サポート',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.coffee, color: Colors.brown),
            title: const Text('開発者にコーヒーを奢る'),
            subtitle: const Text('300円で開発を支援する'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              PaymentService().buyCoffee();
            },
          ),
        ],
      ),
    );
  }
}
