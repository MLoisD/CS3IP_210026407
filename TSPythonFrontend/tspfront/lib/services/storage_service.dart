import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/mood_entry.dart';
import '../models/journal_entry.dart';

class StorageService {
  static const String MOOD_FILENAME = 'mood_entries.csv';
  static const String JOURNAL_FILENAME = 'journal_entries.csv';
  
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  
  Future<File> get _moodFile async {
    final path = await _localPath;
    return File('$path/$MOOD_FILENAME');
  }
  
  Future<File> get _journalFile async {
    final path = await _localPath;
    return File('$path/$JOURNAL_FILENAME');
  }
  
  Future<void> initializeFiles() async {
    try {
      final moodFile = await _moodFile;
      final journalFile = await _journalFile;
      
      if (!await moodFile.exists()) {
        await moodFile.writeAsString('date,moodScore,activities,sleepHours,sleepQuality\n');
      }
      
      if (!await journalFile.exists()) {
        await journalFile.writeAsString('date,content,associatedMood\n');
      }
    } catch (e) {
      debugPrint('Error initializing files: $e');
    }
  }
  
  Future<void> saveMoodEntry(MoodEntry entry) async {
    try {
      final file = await _moodFile;
      await file.writeAsString('${entry.toCsvRow()}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Error saving mood entry: $e');
      rethrow;
    }
  }
  
  Future<List<MoodEntry>> getMoodEntries() async {
    try {
      final file = await _moodFile;
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      return contents.split('\n')
        .skip(1)
        .where((line) => line.trim().isNotEmpty)
        .map<MoodEntry>((line) => MoodEntry.fromCsvRow(line))
        .toList()
        .reversed
        .toList();
    } catch (e) {
      debugPrint('Error reading mood entries: $e');
      return [];
    }
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    try {
      final file = await _journalFile;
      await file.writeAsString('${entry.toCsvRow()}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Error saving journal entry: $e');
      rethrow;
    }
  }
  
  Future<List<JournalEntry>> getJournalEntries() async {
    try {
      final file = await _journalFile;
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      return contents.split('\n')
        .skip(1)
        .where((line) => line.trim().isNotEmpty)
        .map<JournalEntry>((line) => JournalEntry.fromCsvRow(line))
        .toList()
        .reversed
        .toList();
    } catch (e) {
      debugPrint('Error reading journal entries: $e');
      return [];
    }
  }
}