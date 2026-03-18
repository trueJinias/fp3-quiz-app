import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

enum QuizMode { normal, review }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final bool isLoading;
  final int? selectedOptionIndex;
  final bool isAnswered;
  final QuizMode mode;
  final String? errorMessage;
  final Map<int, String>? nextIntervalLabels;

  QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.isLoading = true,
    this.selectedOptionIndex,
    this.isAnswered = false,
    this.mode = QuizMode.normal,
    this.errorMessage,
    this.nextIntervalLabels,
  });

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? score,
    bool? isLoading,
    int? selectedOptionIndex,
    bool? isAnswered,
    QuizMode? mode,
    String? errorMessage,
    Map<int, String>? nextIntervalLabels,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      selectedOptionIndex: selectedOptionIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      mode: mode ?? this.mode,
      errorMessage: errorMessage,
      nextIntervalLabels: nextIntervalLabels ?? this.nextIntervalLabels,
    );
  }

  bool get isCompleted => !isLoading && questions.isNotEmpty && currentIndex >= questions.length;
  Question get currentQuestion => questions[currentIndex];
}

// Top-level function for compute
List<Question> _parseJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((j) => Question.fromJson(j)).toList();
}

class QuizNotifier extends StateNotifier<QuizState> {
  final ReviewService _reviewService = ReviewService();
  List<Question> _allQuestions = [];
  final Set<int> _againRatedIds = {};

  QuizNotifier() : super(QuizState());

  Future<void> _loadData() async {
    final String jsonString = await rootBundle.loadString('assets/questions.json');
    _allQuestions = await compute(_parseJson, jsonString);
  }

  Future<void> _ensureLoaded() async {
    if (_allQuestions.isEmpty) {
      await _loadData();
    }
  }

  Future<void> startNormalQuiz() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _ensureLoaded();
      if (!mounted) return;
      
      if (_allQuestions.isEmpty) {
         if (mounted) state = state.copyWith(isLoading: false, errorMessage: '問題データが空です。(JSON Load Error?)');
         return;
      }
      
      final settingsService = SettingsService();
      final limit = await settingsService.getNewCardsPerDay();
      final alreadyDone = await _reviewService.getNewCardsCountToday();
      final remaining = limit - alreadyDone;
      
      if (remaining <= 0) {
        // 通知をリスケジュール（失敗してもクイズ画面には影響しない）
        try {
          await NotificationService().completeForToday();
        } catch (e) {
          debugPrint('Notification error (non-critical): $e');
        }

        if (mounted) {
          state = QuizState(
            questions: [],
            isLoading: false,
            mode: QuizMode.normal,
            errorMessage: '本日の学習ノルマ(${limit}問)を達成済みです。\n(${alreadyDone}問 完了済み)',
          );
        }
        return;
      }
      
      final learnedIds = await _reviewService.getLearnedQuestionIds();
      final newQuestions = _allQuestions.where((q) => !learnedIds.contains(q.id)).toList();
      
      if (newQuestions.isEmpty) {
         if (mounted) {
           state = QuizState(
            questions: [],
            isLoading: false,
            mode: QuizMode.normal,
            errorMessage: 'すべての問題を学習済みです！\n(全${_allQuestions.length}問)',
          );
         }
        return;
      }
      
      final countToTake = remaining < 10 ? remaining : 10;
      final shuffled = listShim(newQuestions)..shuffle();
      final quizQuestions = shuffled.take(countToTake).toList();
      
      if (quizQuestions.isEmpty) {
         if (mounted) state = state.copyWith(isLoading: false, errorMessage: '予期せぬエラー: 出題データ作成失敗');
         return;
      }
      
      if (mounted) {
        state = QuizState(
          questions: quizQuestions,
          isLoading: false,
          mode: QuizMode.normal,
          errorMessage: null,
        );
      }
    } catch (e) {
       print('Quiz Error: $e');
       if (mounted) state = state.copyWith(isLoading: false, errorMessage: 'エラーが発生しました: $e');
    }
  }

  Future<void> startReviewQuiz() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _ensureLoaded();
      if (!mounted) return;
      
      if (_allQuestions.isEmpty) {
         if (mounted) state = state.copyWith(isLoading: false, errorMessage: '問題データがロードされていません。');
         return;
      }

      final dueIds = await _reviewService.getDueQuestionIds();
      
      if (dueIds.isEmpty) {
         if (mounted) {
           state = QuizState(
            questions: [],
            isLoading: false,
            mode: QuizMode.review,
            errorMessage: '現在、復習すべき問題はありません。',
          );
         }
        return;
      }

      final reviewQuestions = _allQuestions.where((q) => dueIds.contains(q.id)).toList();
      
      if (mounted) {
        state = QuizState(
          questions: reviewQuestions,
          isLoading: false,
          mode: QuizMode.review,
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, errorMessage: '復習モードエラー: $e');
    }
  }

  Future<void> selectOption(int index) async {
    if (state.isAnswered) return;

    final question = state.currentQuestion;
    final isCorrect = index == question.correctIndex;

    // Dynamically calculate labels based on the actual algorithm in ReviewService
    final calc1 = await _reviewService.calculateNextReview(question.id, 1);
    final calc2 = await _reviewService.calculateNextReview(question.id, 2);
    final calc3 = await _reviewService.calculateNextReview(question.id, 3);
    final calc4 = await _reviewService.calculateNextReview(question.id, 4);

    String labelForCalc(Map<String, dynamic> calc) {
      int interval = calc['interval'] as int;
      if (interval == 0) return '今日';
      if (interval == 1) return '明日';
      return '$interval日後';
    }

    final labels = <int, String>{
      1: '今回',    // Again: always show '今回'
      2: '今日',    // Hard: always show '今日'
      3: labelForCalc(calc3),
      4: labelForCalc(calc4),
    };

    if (mounted) {
      state = state.copyWith(
        selectedOptionIndex: index,
        isAnswered: true,
        score: isCorrect ? state.score + 1 : state.score,
        nextIntervalLabels: labels,
      );
    }
  }

  Future<void> handleBackPress() async {
    if (state.isAnswered && state.questions.isNotEmpty &&
        state.currentIndex < state.questions.length) {
      final question = state.currentQuestion;
      await _reviewService.saveReview(question.id, 2);
      _againRatedIds.remove(question.id);
    }
    for (final id in _againRatedIds) {
      await _reviewService.saveReview(id, 2);
    }
    _againRatedIds.clear();
  }

  Future<void> rateQuestion(int rating) async {
    final question = state.currentQuestion;
    await _reviewService.saveReview(question.id, rating);

    if (rating == 1) {
      _againRatedIds.add(question.id);
    } else {
      _againRatedIds.remove(question.id);
    }

    var currentQuestions = List<Question>.from(state.questions);

    if (rating == 1) {
      final insertIndex = (state.currentIndex + 1 + 10).clamp(0, currentQuestions.length);
      if (insertIndex >= currentQuestions.length) {
         currentQuestions.add(question);
      } else {
         currentQuestions.insert(insertIndex, question);
      }
    }

    if (state.currentIndex < currentQuestions.length) {
       state = state.copyWith(questions: currentQuestions);
       nextQuestion();
    }
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length) {
      state = QuizState(
        questions: state.questions,
        currentIndex: state.currentIndex + 1,
        score: state.score,
        isLoading: false,
        selectedOptionIndex: null,
        isAnswered: false,
        mode: state.mode,
        errorMessage: null,
      );
    }
  }

  void resetQuiz() {
    startNormalQuiz();
  }
  
  List<T> listShim<T>(List<T> list) => List<T>.from(list);
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

final dueQuestionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ReviewService();
  final dueIds = await service.getDueQuestionIds();
  return dueIds.length;
});

final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ReviewService().getStats();
});

final futureReviewsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  return ReviewService().getFutureReviews(7);
});
