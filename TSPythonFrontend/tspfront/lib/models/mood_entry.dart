class MoodEntry {
  final DateTime date;
  final int moodScore;
  final List<String> activities;
  final int sleepHours;
  final int sleepQuality;

  MoodEntry({
    required this.date,
    required this.moodScore,
    this.activities = const [],
    this.sleepHours = 0,
    this.sleepQuality = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'moodScore': moodScore,
      'activities': activities.join(','),
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      date: DateTime.parse(map['date']),
      moodScore: map['moodScore'],
      activities: map['activities'].split(',').where((s) => s.isNotEmpty).toList(),
      sleepHours: map['sleepHours'],
      sleepQuality: map['sleepQuality'],
    );
  }

  String toCsvRow() {
    return '${date.toIso8601String()},$moodScore,${activities.join('|')},$sleepHours,$sleepQuality';
  }

  factory MoodEntry.fromCsvRow(String row) {
    final parts = row.split(',');
    return MoodEntry(
      date: DateTime.parse(parts[0]),
      moodScore: int.parse(parts[1]),
      activities: parts[2].split('|').where((s) => s.isNotEmpty).toList(),
      sleepHours: int.parse(parts[3]),
      sleepQuality: int.parse(parts[4]),
    );
  }
}