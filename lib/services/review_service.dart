import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static const String _keyReviewData = 'review_data';
  static const String _keyDailyStats = 'daily_stats';

  Future<Map<String, dynamic>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyReviewData);
    if (jsonString == null) return {};
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReviewData, json.encode(data));
  }

  Future<void> _incrementDailyNewCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String nowKey = _getTodayKey();
    
    String? statsString = prefs.getString(_keyDailyStats);
    Map<String, dynamic> stats = statsString != null ? json.decode(statsString) : {};
    
    Map<String, dynamic> todayStats = stats[nowKey] != null ? Map<String, dynamic>.from(stats[nowKey]) : {'new': 0, 'review': 0};
    todayStats['new'] = (todayStats['new'] as int) + 1;
    
    stats[nowKey] = todayStats;
    await prefs.setString(_keyDailyStats, json.encode(stats));
  }
  
  Future<int> getNewCardsCountToday() async {
    final prefs = await SharedPreferences.getInstance();
    final String nowKey = _getTodayKey();
    
    String? statsString = prefs.getString(_keyDailyStats);
    if (statsString == null) return 0;
    
    Map<String, dynamic> stats = json.decode(statsString);
    if (stats[nowKey] == null) return 0;
    
    return stats[nowKey]['new'] ?? 0;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Future<Map<String, dynamic>> calculateNextReview(int questionId, int rating) async {
    final data = await _loadData();
    final String idStr = questionId.toString();
    
    Map<String, dynamic> itemData = data[idStr] ?? {
      'interval': 0,
      'step': 0,
      'ease': 2.5,
    };
    
    int interval = itemData['interval'] as int? ?? 0;
    int step = itemData['step'] as int? ?? 0;
    double ease = itemData['ease'] as double? ?? 2.5;
    
    int delayMinutes = 0;
    
    // Custom Logic:
    // 1 (Again): Re-queue in session. Scheduler: 1 min.
    // 2 (Hard): "Today". Scheduler: 5 hours.
    // 3 (Good): "Tomorrow". Scheduler: 1 day.
    // 4 (Easy): 3 days.

    if (rating == 1) { // Again
      interval = 0;
      step = 0;
      delayMinutes = 1;
      ease = (ease - 0.2).clamp(1.3, 5.0);
    } else if (rating == 2) { // Hard
       interval = 0; 
       step = 0;
       delayMinutes = 300; // 5 hours
       ease = (ease - 0.15).clamp(1.3, 5.0);
    } else if (rating == 3) { // Good
       if (interval == 0) {
         interval = 1;
         delayMinutes = 1440; // 1 day
         step = 0;
       } else {
         interval = (interval * ease).round();
         if (interval < 1) interval = 1;
         delayMinutes = interval * 1440;
       }
    } else if (rating == 4) { // Easy
       if (interval == 0) {
         interval = 3;
         delayMinutes = 3 * 1440;
       } else {
         interval = (interval * ease * 1.5).round();
         if (interval <= 1) interval = 3;
         delayMinutes = interval * 1440;
         ease += 0.15;
       }
    }
    
    if (ease > 5.0) ease = 5.0;
    
    int nextReview = DateTime.now().add(Duration(minutes: delayMinutes)).millisecondsSinceEpoch;
    
    return {
       'nextReview': nextReview,
       'interval': interval,
       'step': step,
       'ease': ease,
       'encodedData': {
         'interval': interval,
         'step': step,
         'ease': ease,
         'nextReview': nextReview,
         'lastReview': DateTime.now().millisecondsSinceEpoch,
       }
    };
  }

  Future<void> saveReview(int questionId, int rating) async {
    final data = await _loadData();
    final String idStr = questionId.toString();
    bool isNew = !data.containsKey(idStr);
    
    if (isNew) {
      await _incrementDailyNewCount();
    }
    
    final calculation = await calculateNextReview(questionId, rating);
    data[idStr] = calculation['encodedData'];
    
    await _saveData(data);
  }

  Future<void> saveReviewStatus(int questionId, bool isCorrect) async {
     await saveReview(questionId, isCorrect ? 3 : 1);
  }

  Future<List<int>> getDueQuestionIds() async {
    final data = await _loadData();
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<int> dueIds = [];

    data.forEach((key, value) {
      final nextReview = value['nextReview'] as int;
      if (nextReview <= now) {
        dueIds.add(int.parse(key));
      }
    });

    return dueIds;
  }
  
  Future<List<int>> getLearnedQuestionIds() async {
    final data = await _loadData();
    return data.keys.map((k) => int.parse(k)).toList();
  }
  
  Future<Map<String, dynamic>> getStats() async {
      final data = await _loadData();
      int learned = data.length;
      int due = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      data.forEach((k, v) {
          if ((v['nextReview'] as int) <= now) due++;
      });
      
      return {
          'learned': learned,
          'due': due,
      };
  }

  Future<List<int>> getFutureReviews(int days) async {
    final data = await _loadData();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final msPerDay = 24 * 60 * 60 * 1000;
    
    List<int> counts = List.filled(days, 0);
    
    data.forEach((k, v) {
      final nextReview = v['nextReview'] as int;
      if (nextReview >= todayStart) {
        final diff = nextReview - todayStart;
        final dayIndex = (diff / msPerDay).floor();
        if (dayIndex >= 0 && dayIndex < days) {
          counts[dayIndex]++;
        }
      }
    });
    
    return counts;
  }

  Future<void> resetAll() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove(_keyReviewData);
     await prefs.remove(_keyDailyStats);
  }
}
