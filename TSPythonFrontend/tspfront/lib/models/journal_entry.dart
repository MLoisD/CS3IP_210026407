class JournalEntry {
  final DateTime date;
  final String title; 
  final String content;
  final List<String> tags;
  final int associatedMood;

  JournalEntry({
    required this.date,
    required this.title, 
    required this.content,
    this.tags = const [], 
    this.associatedMood = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'title': title, 
      'content': content,
      'tags': tags.join(','), 
      'associatedMood': associatedMood,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      date: DateTime.parse(map['date']),
      title: map['title'], 
      content: map['content'],
      tags: map['tags'].split(',').where((s) => s.isNotEmpty).toList(), 
      associatedMood: map['associatedMood'],
    );
  }

  String toCsvRow() {
    final escapedContent = content.replaceAll('"', '""');
    final escapedTitle = title.replaceAll('"', '""'); 
    return '${date.toIso8601String()},"$escapedTitle","$escapedContent","${tags.join('|')}",$associatedMood';
  }

  factory JournalEntry.fromCsvRow(String row) {
    List<String> parts = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < row.length; i++) {
      if (row[i] == '"') {
        if (i + 1 < row.length && row[i + 1] == '"') {

          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (row[i] == ',' && !inQuotes) {
        parts.add(current);
        current = '';
      } else {
        current += row[i];
      }
    }
    parts.add(current);
    
    return JournalEntry(
      date: DateTime.parse(parts[0]),
      title: parts[1], 
      content: parts[2],
      tags: parts[3].split('|').where((s) => s.isNotEmpty).toList(), 
      associatedMood: int.parse(parts[4]),
    );
  }
}