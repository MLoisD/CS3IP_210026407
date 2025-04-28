import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class MoodChartPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final DateTime startDate;
  final DateTime endDate;
  
  MoodChartPainter({
    required this.entries,
    required this.startDate,
    required this.endDate,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final dotPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
      ..color = Colors.grey.withValues()
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 10; i++) {
      final y = size.height - (i / 10) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    
    final totalDays = endDate.difference(startDate).inDays + 1;
    
    if (entries.length > 1) {
      final path = Path();
      bool firstPoint = true;
      
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final dayOffset = entry.date.difference(startDate).inDays;
        final x = (dayOffset / totalDays) * size.width;
        final y = size.height - ((entry.moodScore / 10) * size.height);
        
        dotPaint.color = _getMoodColor(entry.moodScore);
        canvas.drawCircle(Offset(x, y), 4, dotPaint);
        
        if (firstPoint) {
          path.moveTo(x, y);
          firstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      

      canvas.drawPath(path, paint);
    } else if (entries.length == 1) {
      final entry = entries[0];
      final dayOffset = entry.date.difference(startDate).inDays;
      final x = (dayOffset / totalDays) * size.width;
      final y = size.height - ((entry.moodScore / 10) * size.height);
      
      dotPaint.color = _getMoodColor(entry.moodScore);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }
  
  Color _getMoodColor(int moodScore) {
    if (moodScore >= 9) return Colors.green[700]!;
    if (moodScore >= 7) return Colors.green[400]!;
    if (moodScore >= 5) return Colors.yellow[600]!;
    if (moodScore >= 3) return Colors.orange;
    return Colors.red;
  }
  
  @override
  bool shouldRepaint(MoodChartPainter oldDelegate) {
    return oldDelegate.entries != entries || 
           oldDelegate.startDate != startDate || 
           oldDelegate.endDate != endDate;
  }
}