import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';

class JournalEntryCard extends StatelessWidget {
  final JournalEntry journalEntry;
  final MoodEntry? moodEntry;
  final VoidCallback onTap;
  final bool isExpanded;

  const JournalEntryCard({
    super.key,
    required this.journalEntry,
    this.moodEntry,
    required this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(journalEntry.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (moodEntry != null) _buildMoodIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                journalEntry.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isExpanded
                    ? journalEntry.content
                    : _truncateContent(journalEntry.content),
                style: const TextStyle(fontSize: 16),
              ),
              if (!isExpanded && journalEntry.content.length > 100)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onTap,
                    child: const Text('Read more'),
                  ),
                ),
              const SizedBox(height: 8),
              _buildEntryTags(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodIndicator() {
    if (moodEntry == null) return const SizedBox();

    String emoji;
    Color color;

    if (moodEntry!.moodScore <= 2) {
      emoji = '😞';
      color = Colors.red.shade300;
    } else if (moodEntry!.moodScore <= 4) {
      emoji = '😔';
      color = Colors.orange.shade300;
    } else if (moodEntry!.moodScore <= 6) {
      emoji = '😐';
      color = Colors.yellow.shade300;
    } else if (moodEntry!.moodScore <= 8) {
      emoji = '🙂';
      color = Colors.lightGreen.shade300;
    } else {
      emoji = '😄';
      color = Colors.green.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            moodEntry!.moodScore.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTags() {
    if (journalEntry.tags.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: journalEntry.tags.map((tag) {
        return Chip(
          label: Text(tag),
          backgroundColor: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: const TextStyle(fontSize: 12),
        );
      }).toList(),
    );
  }

  String _truncateContent(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}