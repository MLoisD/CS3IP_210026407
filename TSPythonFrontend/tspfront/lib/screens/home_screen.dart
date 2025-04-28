import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<MoodEntry> _recentMoodEntries = [];
  double _weeklyAverage = 0;
  double _monthlyAverage = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    
    final entries = await _storageService.getMoodEntries();
    
    if (entries.isEmpty) {
      setState(() {
        _recentMoodEntries = [];
        _weeklyAverage = 0;
        _monthlyAverage = 0;
        _isLoading = false;
      });
      return;
    }
    
    // Calculate weekly average
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEntries = entries.where((entry) => 
      entry.date.isAfter(weekStart.subtract(Duration(days: 1))) &&
      entry.date.isBefore(now.add(Duration(days: 1)))
    ).toList();
    
    double weeklySum = 0;
    for (var entry in weekEntries) {
      weeklySum += entry.moodScore;
    }
    
    // Calculate monthly average
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEntries = entries.where((entry) => 
      entry.date.isAfter(monthStart.subtract(Duration(days: 1))) &&
      entry.date.isBefore(now.add(Duration(days: 1)))
    ).toList();
    
    double monthlySum = 0;
    for (var entry in monthEntries) {
      monthlySum += entry.moodScore;
    }
    
    setState(() {
      _recentMoodEntries = entries.take(5).toList();
      _weeklyAverage = weekEntries.isNotEmpty ? weeklySum / weekEntries.length : 0;
      _monthlyAverage = monthEntries.isNotEmpty ? monthlySum / monthEntries.length : 0;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    SizedBox(height: 24),
                    _buildWeatherWidget(),
                    SizedBox(height: 24),
                    _buildMoodSummary(),
                    SizedBox(height: 24),
                    _buildRecentMoods(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildWeatherWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny,
            color: Colors.white,
            size: 48,
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '15°C',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Sunny',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Birmingham',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoodSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAverageCard(
                  'Weekly Average',
                  _weeklyAverage,
                  Colors.blue[100]!,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAverageCard(
                  'Monthly Average',
                  _monthlyAverage,
                  Colors.green[100]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAverageCard(String title, double average, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                average >= 7
                    ? Icons.sentiment_very_satisfied
                    : average >= 4
                        ? Icons.sentiment_neutral
                        : Icons.sentiment_dissatisfied,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentMoods() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Moods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _recentMoodEntries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No mood entries yet. Add your first mood!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _recentMoodEntries
                      .map((entry) => _buildMoodEntry(entry))
                      .toList(),
                ),
        ],
      ),
    );
  }
  
  Widget _buildMoodEntry(MoodEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: moodColors[entry.moodScore].withValues(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                moodIcons[entry.moodScore],
                color: moodColors[entry.moodScore],
                size: 28,
              ),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(entry.date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                entry.activities.isNotEmpty
                    ? entry.activities.join(', ')
                    : 'No activities recorded',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}