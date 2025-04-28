import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';


class MoodCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, MoodEntry> moodEntries;
  
  const MoodCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.moodEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(context),
        const SizedBox(height: 16),
        _buildCalendarGrid(context),
      ],
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMM d, yyyy').format(selectedDate),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () {
                final previousMonth = DateTime(
                  selectedDate.year, 
                  selectedDate.month - 1, 
                  1
                );
                onDateSelected(previousMonth);
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              onPressed: () {
                final nextMonth = DateTime(
                  selectedDate.year, 
                  selectedDate.month + 1, 
                  1
                );
                onDateSelected(nextMonth);
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final daysInMonth = DateTime(
      selectedDate.year, 
      selectedDate.month + 1, 
      0
    ).day;
    
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tue', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Thu', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekdayOfMonth + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekdayOfMonth) {
              return Container();
            }
            
            final day = index - firstWeekdayOfMonth + 1;
            final currentDate = DateTime(selectedDate.year, selectedDate.month, day);
            final hasMoodEntry = moodEntries.containsKey(DateUtils.dateOnly(currentDate));
            
            return GestureDetector(
              onTap: () => onDateSelected(currentDate),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DateUtils.isSameDay(currentDate, selectedDate) 
                      ? Theme.of(context).primaryColor.withValues()
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: TextStyle(
                        fontWeight: DateUtils.isSameDay(currentDate, DateTime.now())
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (hasMoodEntry)
                      _getMoodEmoji(moodEntries[DateUtils.dateOnly(currentDate)]!.moodScore),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getMoodEmoji(int moodScore) {
    String emoji;
    
    if (moodScore <= 2) {
      emoji = '😞';
    } else if (moodScore <= 4) {
      emoji = '😔';
    } else if (moodScore <= 6) {
      emoji = '😐';
    } else if (moodScore <= 8) {
      emoji = '🙂';
    } else {
      emoji = '😄';
    }

    return Text(
      emoji,
      style: const TextStyle(fontSize: 20),
    );
  }
}