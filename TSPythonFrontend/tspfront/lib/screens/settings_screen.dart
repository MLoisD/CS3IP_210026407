import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Enable dark theme for the app'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          ListTile(
            title: Text('Language'),
            subtitle: Text(_language),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showLanguageSelector,
          ),
          Divider(),
          
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: Text('Enable Notifications'),
            subtitle: Text('Receive daily reminders'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          ListTile(
            title: Text('Reminder Time'),
            subtitle: Text('8:00 PM'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
            },
          ),
          Divider(),
          
          _buildSectionHeader('Data'),
          ListTile(
            title: Text('Export Data'),
            subtitle: Text('Save your data as CSV'),
            trailing: Icon(Icons.file_download),
            onTap: _exportData,
          ),
          ListTile(
            title: Text('Import Data'),
            subtitle: Text('Load data from CSV file'),
            trailing: Icon(Icons.file_upload),
            onTap: () {
              // Show file picker
            },
          ),
          ListTile(
            title: Text('Clear All Data'),
            subtitle: Text('Delete all your mood and journal entries'),
            trailing: Icon(Icons.delete_outline, color: Colors.red),
            onTap: _showDeleteConfirmation,
          ),
          Divider(),
        
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  void _showLanguageSelector() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(languages[index]),
                  value: languages[index],
                  groupValue: _language,
                  onChanged: (value) {
                    setState(() {
                      _language = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _exportData() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final moodFile = File('${directory.path}/mood_entries.csv');
    final journalFile = File('${directory.path}/journal_entries.csv');
    
    if (await moodFile.exists() && await journalFile.exists()) {
      final xMoodFile = XFile(moodFile.path);
      final xJournalFile = XFile(journalFile.path);
      
      await Share.shareXFiles(
        [xMoodFile, xJournalFile],
        text: 'Here is your data export',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data to export')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error exporting data: $e')),
    );
  }
}
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete All Data'),
          content: Text(
            'Are you sure you want to delete all your mood and journal entries? '
            'This action cannot be undone.'
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final moodFile = File('${directory.path}/mood_entries.csv');
                  final journalFile = File('${directory.path}/journal_entries.csv');
                  
                  if (await moodFile.exists()) {
                    await moodFile.delete();
                  }
                  
                  if (await journalFile.exists()) {
                    await journalFile.delete();
                  }
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All data deleted')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting data: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}