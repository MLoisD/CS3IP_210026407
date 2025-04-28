import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodAnalyticsService {
  double calculateAverageMood(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    
    int total = entries.fold(0, (sum, entry) => sum + entry.moodScore);
    return total / entries.length;
  }
  
  List<MoodEntry> getEntriesInRange(List<MoodEntry> allEntries, DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    
    return allEntries.where((entry) => 
      entry.date.isAfter(startDate.subtract(Duration(seconds: 1))) && 
      entry.date.isBefore(endDate.add(Duration(seconds: 1)))
    ).toList();
  }
  
  List<MoodEntry> getWeekEntries(List<MoodEntry> allEntries) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endDate = startDate.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    
    return getEntriesInRange(allEntries, startDate, endDate);
  }
  
  List<MoodEntry> getMonthEntries(List<MoodEntry> allEntries) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = (now.month < 12) 
      ? DateTime(now.year, now.month + 1, 0, 23, 59, 59)
      : DateTime(now.year + 1, 1, 0, 23, 59, 59);
    
    return getEntriesInRange(allEntries, startDate, endDate);
  }
  
  String calculateMoodTrend(List<MoodEntry> entries) {
    if (entries.length < 3) return "Not enough data";
    entries.sort((a, b) => a.date.compareTo(b.date));
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = entries.length;
    
    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = entries[i].moodScore.toDouble();
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    if (slope > 0.1) return "Improving";
    if (slope < -0.1) return "Declining";
    return "Stable";
  }
  
  Map<String, double> getPositiveActivityCorrelations(List<MoodEntry> entries) {
    Map<String, List<int>> activityScores = {};
    
    for (var entry in entries) {
      for (var activity in entry.activities) {
        if (!activityScores.containsKey(activity)) {
          activityScores[activity] = [];
        }
        activityScores[activity]!.add(entry.moodScore);
      }
    }
    
    Map<String, double> result = {};
    activityScores.forEach((activity, scores) {
      if (scores.length >= 2) {
        double average = scores.reduce((a, b) => a + b) / scores.length;
        result[activity] = average;
      }
    });
    
    return result;
  }
  
  double predictMood(List<MoodEntry> recentEntries, List<String> plannedActivities) {
    if (recentEntries.isEmpty) return 5.0;
    Map<String, double> activityImpacts = getPositiveActivityCorrelations(recentEntries);
    List<MoodEntry> last3Days = recentEntries.length > 3 
      ? recentEntries.sublist(recentEntries.length - 3) 
      : recentEntries;
    
    double baseMood = calculateAverageMood(last3Days);

    double activityImpact = 0;
    int matchedActivities = 0;
    
    for (var activity in plannedActivities) {
      if (activityImpacts.containsKey(activity)) {
        activityImpact += activityImpacts[activity]! - 5.0;
        matchedActivities++;
      }
    }
    
    if (matchedActivities > 0) {
      double adjustedMood = baseMood + (activityImpact / matchedActivities);
      return adjustedMood.clamp(1.0, 10.0);
    }
    
    return baseMood;
  }
  
  String generateMoodReport(List<MoodEntry> entries, DateTime startDate, DateTime endDate) {
    if (entries.isEmpty) return "No mood data available for this period.";
    
    final dateFormat = DateFormat('MMM d');
    final period = "${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}";
    
    double avgMood = calculateAverageMood(entries);
    String trend = calculateMoodTrend(entries);
    
    // Find best and worst days
    entries.sort((a, b) => b.moodScore.compareTo(a.moodScore));
    final bestDay = entries.first;
    final worstDay = entries.last;
    
    // Common activities
    Map<String, int> activityCount = {};
    for (var entry in entries) {
      for (var activity in entry.activities) {
        activityCount[activity] = (activityCount[activity] ?? 0) + 1;
      }
    }
    
    List<MapEntry<String, int>> sortedActivities = activityCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String topActivities = sortedActivities.isEmpty ? "None recorded" : 
      sortedActivities.take(3).map((e) => "${e.key} (${e.value}x)").join(", ");
    
    return """
    Mood Report for $period
    
    Average Mood: ${avgMood.toStringAsFixed(1)}/10
    Mood Trend: $trend
    
    Best Day: ${dateFormat.format(bestDay.date)} - ${bestDay.moodScore}/10
    Activities: ${bestDay.activities.join(', ')}
    
    Most Challenging Day: ${dateFormat.format(worstDay.date)} - ${worstDay.moodScore}/10
    Activities: ${worstDay.activities.join(', ')}
    
    Top Activities: $topActivities
    """;
  }
}