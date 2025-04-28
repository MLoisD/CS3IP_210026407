import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';

class AddMoodScreen extends StatefulWidget {
  @override
  _AddMoodScreenState createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  final _formKey = GlobalKey<FormState>();
  //final StorageService _storageService = StorageService();

  int _moodScore = 5;
  List<String> _activities = [];
  int _sleepHours = 8;
  int _sleepQuality = 3;
  final List<String> _availableActivities = [
    'Exercise',
    'Reading',
    'Socializing',
    'Work',
    'Meditation',
    'Hobbies',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Your Mood'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveEntry)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSection(),
              SizedBox(height: 24),
              _buildMoodSlider(),
              SizedBox(height: 32),
              _buildActivitySelection(),
              SizedBox(height: 32),
              _buildSleepInputs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMM d').format(DateTime.now()),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'How are you feeling today?',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMoodSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mood Score: $_moodScore', style: TextStyle(fontSize: 16)),
        Slider(
          value: _moodScore.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: _moodScore.toString(),
          onChanged: (value) => setState(() => _moodScore = value.round()),
        ),
      ],
    );
  }

  Widget _buildActivitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activities', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8,
          children:
              _availableActivities.map((activity) {
                final isSelected = _activities.contains(activity);
                return FilterChip(
                  label: Text(activity),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _activities.add(activity);
                      } else {
                        _activities.remove(activity);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSleepInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep', style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _sleepHours.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Hours'),
                onChanged:
                    (value) => _sleepHours = int.tryParse(value) ?? _sleepHours,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Text('Quality: $_sleepQuality/5'),
                  Slider(
                    value: _sleepQuality.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged:
                        (value) =>
                            setState(() => _sleepQuality = value.round()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveEntry() async {
    try {
      final newEntry = MoodEntry(
        date: DateTime.now(),
        moodScore: _moodScore,
        activities: _activities,
        sleepHours: _sleepHours,
        sleepQuality: _sleepQuality,
      );

      await StorageService().saveMoodEntry(newEntry);
      Navigator.pop(context, true); // Trigger refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save entry: ${e.toString()}')),
      );
    }
  }
}
