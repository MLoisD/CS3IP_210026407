import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final StorageService _storageService = StorageService();
  List<JournalEntry> _journalEntries = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadJournalEntries();
  }
  
  Future<void> _loadJournalEntries() async {
    setState(() => _isLoading = true);
    final entries = await _storageService.getJournalEntries();
    setState(() {
      _journalEntries = entries;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Journal'), actions: [IconButton(icon: Icon(Icons.search), onPressed: () {})]),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _journalEntries.isEmpty
              ? SingleChildScrollView(
                child: _buildEmptyState()
              )
              : _buildJournalList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddJournalEntryDialog(context),
        tooltip: 'Add Journal Entry',
        child: Icon(Icons.edit),
      ),
    );
  }

Widget _buildEmptyState() {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('Your journal is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text('Tap the + button to add your first entry', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    ),
  );
}

  Widget _buildJournalList() {
    Map<String, List<JournalEntry>> entriesByMonth = {};
    
    for (var entry in _journalEntries) {
      final monthYear = DateFormat('MMMM yyyy').format(entry.date);
      entriesByMonth.putIfAbsent(monthYear, () => []).add(entry);
    }
    
    return ListView.builder(
      itemCount: entriesByMonth.length,
      itemBuilder: (context, index) {
        final monthYear = entriesByMonth.keys.elementAt(index);
        final entries = entriesByMonth[monthYear]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(monthYear, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, idx) {
                final entry = entries[idx];
                return ListTile(
                  title: Text(
                    entry.title.isNotEmpty 
                        ? entry.title 
                        : DateFormat('EEEE, MMMM d').format(entry.date),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    entry.content.length > 50
                        ? '${entry.content.substring(0, 50)}...'
                        : entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _showJournalEntryDetail(entry),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showJournalEntryDetail(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.title.isNotEmpty)
                              Text(entry.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(entry.content, style: TextStyle(fontSize: 16, height: 1.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddJournalEntryDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Journal Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    child: Text('Save'),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                        final newEntry = JournalEntry(
                          date: DateTime.now(),
                          title: titleController.text,
                          content: contentController.text,
                        );
                        await _storageService.saveJournalEntry(newEntry);
                        _loadJournalEntries();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()), style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Entry title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'How was your day?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}