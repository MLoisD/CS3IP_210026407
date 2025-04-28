import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storageService = StorageService();
  List<MoodEntry> _moodEntries = [];
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMoodEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodEntries() async {
    final entries = await _storageService.getMoodEntries();
    setState(() {
      _moodEntries = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(_selectedMonth),
                  style: TextStyle(fontSize: 16),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCalendarView(),
            _buildMoodFlowSection(),
            _buildTimelineSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final dayOffset = firstDayOfMonth.weekday % 7;
    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),


          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                dayLabels
                    .map(
                      (label) => Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),

          SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: dayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < dayOffset) {
                return Container(); 
              }

              final day = index - dayOffset + 1;
              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                day,
              );

              final moodEntry = _moodEntries.firstWhere(
                (entry) =>
                    entry.date.year == date.year &&
                    entry.date.month == date.month &&
                    entry.date.day == date.day,
                orElse: () => MoodEntry(date: date, moodScore: 0),
              );

              return _buildMoodCell(day, moodEntry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCell(int day, MoodEntry moodEntry) {
    final hasMood = moodEntry.moodScore > 0;
    final now = DateTime.now();
    final isToday =
        day == now.day &&
        _selectedMonth.month == now.month &&
        _selectedMonth.year == now.year;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Center(
        child:
            hasMood
                ? Icon(
                  moodIcons[moodEntry.moodScore],
                  color: moodColors[moodEntry.moodScore],
                  size: 28,
                )
                : Text(
                  day.toString(),
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
      ),
    );
  }

  Widget _buildMoodFlowSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Flow',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 16),

          _moodEntries.isNotEmpty
              ?
              SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No Record',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
              : SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No Record',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

          SizedBox(height: 24),

          Text(
            'Mood Bar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 16),

          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                _moodEntries.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 20,
                            child: Container(color: Colors.green[200]),
                          ),
                          Expanded(
                            flex: 30,
                            child: Container(color: Colors.blue[200]),
                          ),
                          Expanded(
                            flex: 50,
                            child: Container(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    )
                    : Container(),
          ),

          SizedBox(height: 8),

          // Mood indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              5,
              (index) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(child: Text('See all'), onPressed: () {}),
            ],
          ),
          _moodEntries.isNotEmpty
              ? ListView.builder(
                shrinkWrap: true,
                physics:
                    NeverScrollableScrollPhysics(),
                itemCount: _moodEntries.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  //final entry = _moodEntries[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(

                    ),
                  );
                },
              )
              : SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                      ),
                      SizedBox(height: 8),
                      Text('No record', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
