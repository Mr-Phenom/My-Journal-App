import 'package:flutter/material.dart';
import 'package:life_journal/screens/add_edit_screen.dart';
import 'package:life_journal/services/database_helper.dart';

class JournalViewScreen extends StatefulWidget {
  final Map<String, dynamic> entry;
  const JournalViewScreen({super.key, required this.entry});

  @override
  State<StatefulWidget> createState() {
    return _JournalViewState();
  }
}

class _JournalViewState extends State<JournalViewScreen> {
  late Map<String, dynamic> currentEntry;

  @override
  void initState() {
    super.initState();
    currentEntry = widget.entry;
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddEditScreen(journalEntry: currentEntry),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        currentEntry = result;
      });
    }
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Journal?'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close the dialog

              // Delete from Database directly
              await DatabaseHelper.instance.delete(currentEntry['id']);

              if (mounted) {
                // Pop the screen and send a "Delete Signal" map back to Home
                Navigator.pop(context, {'delete': true});
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, currentEntry);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Journal"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              onPressed: _navigateToEdit,
              icon: Icon(Icons.edit),
              color: Colors.white,
            ),
            IconButton(
              onPressed: _deleteEntry,
              icon: Icon(Icons.delete, color: Colors.red),
            ),
            SizedBox(width: 9),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentEntry['date'],
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16),
              Text(
                currentEntry['title'],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // color: Colors.black87,
                ),
              ),
              SizedBox(height: 24),
              Text(
                currentEntry['snippet'],
                style: TextStyle(
                  // color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Text('Mood: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(
                    currentEntry['mood'],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
