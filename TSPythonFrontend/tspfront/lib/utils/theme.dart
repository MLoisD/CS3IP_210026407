import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  fontFamily: 'Roboto',
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
  ),
);


final List<Color> moodColors = [
  Colors.grey,        // No mood
  Colors.red[300]!,   // 1 - Very bad
  Colors.orange[300]!, // 2
  Colors.amber[300]!, // 3
  Colors.yellow[300]!, // 4
  Colors.lime[300]!,  // 5
  Colors.lightGreen[300]!, // 6
  Colors.green[300]!, // 7
  Colors.teal[300]!,  // 8
  Colors.blue[300]!,  // 9
  Colors.indigo[300]!, // 10 - Excellent
];

final List<IconData> moodIcons = [
  Icons.sentiment_very_dissatisfied,  // No mood
  Icons.sentiment_very_dissatisfied,  // 1
  Icons.sentiment_dissatisfied,       // 2
  Icons.sentiment_dissatisfied,       // 3
  Icons.sentiment_neutral,            // 4
  Icons.sentiment_neutral,            // 5
  Icons.sentiment_neutral,            // 6
  Icons.sentiment_satisfied,          // 7
  Icons.sentiment_satisfied,          // 8
  Icons.sentiment_very_satisfied,     // 9
  Icons.sentiment_very_satisfied,     // 10
];

final List<String> activityCategories = [
  'Exercise',
  'Work',
  'Social',
  'Hobby',
  'Rest',
  'Reading',
  'Entertainment',
  'Meditation',
  'Family',
  'Travel',
  'Outdoor',
  'Cooking',
  'Learning',
  'Shopping',
  'Cleaning',
];

String formatDate(DateTime date) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatMonthYear(DateTime date) {
  final months = [
    'January', 'February', 'March', 'April', 'May', 'June', 
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[date.month - 1]} ${date.year}';
}