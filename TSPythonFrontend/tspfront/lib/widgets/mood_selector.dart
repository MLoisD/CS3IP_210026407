import 'package:flutter/material.dart';

class MoodSelector extends StatefulWidget {
  final int initialValue;
  final Function(int) onMoodSelected;
  final bool showLabels;
  final bool showValues;

  const MoodSelector({
    super.key,
    this.initialValue = 5,
    required this.onMoodSelected,
    this.showLabels = true,
    this.showValues = true,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  late int _selectedMood;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        _buildMoodGrid(),
        const SizedBox(height: 16),
        _buildMoodSlider(),
      ],
    );
  }

  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        final moodValue = index + 1;
        final isSelected = moodValue == _selectedMood;
        
        return _buildMoodButton(moodValue, isSelected);
      },
    );
  }

  Widget _buildMoodButton(int value, bool isSelected) {
    String emoji;
    Color backgroundColor;
    
    if (value <= 2) {
      emoji = '😞';
      backgroundColor = Colors.red.shade100;
    } else if (value <= 4) {
      emoji = '😔';
      backgroundColor = Colors.orange.shade100;
    } else if (value <= 6) {
      emoji = '😐';
      backgroundColor = Colors.yellow.shade100;
    } else if (value <= 8) {
      emoji = '🙂';
      backgroundColor = Colors.lightGreen.shade100;
    } else {
      emoji = '😄';
      backgroundColor = Colors.green.shade100;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = value;
        });
        widget.onMoodSelected(value);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: backgroundColor.withRed(backgroundColor.red - 40).withGreen(backgroundColor.green - 40),
                  width: 2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withValues(),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            if (widget.showValues)
              Text(
                value.toString(),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getColorForMood(_selectedMood),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: _getColorForMood(_selectedMood),
            overlayColor: _getColorForMood(_selectedMood).withValues(),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            trackHeight: 8,
          ),
          child: Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: _selectedMood.toDouble(),
            onChanged: (value) {
              setState(() {
                _selectedMood = value.round();
              });
              widget.onMoodSelected(_selectedMood);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Very Bad', style: TextStyle(color: Colors.grey)),
              Text(
                _getMoodLabel(_selectedMood),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getColorForMood(_selectedMood),
                ),
              ),
              const Text('Very Good', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForMood(int value) {
    if (value <= 2) {
      return Colors.red;
    } else if (value <= 4) {
      return Colors.orange;
    } else if (value <= 6) {
      return Colors.yellow.shade600;
    } else if (value <= 8) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }

  String _getMoodLabel(int value) {
    if (value <= 2) {
      return 'Terrible';
    } else if (value <= 4) {
      return 'Bad';
    } else if (value <= 6) {
      return 'Okay';
    } else if (value <= 8) {
      return 'Good';
    } else {
      return 'Excellent';
    }
  }
}