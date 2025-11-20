import 'package:flutter/material.dart';
import 'package:life_journal/screens/add_edit_screen.dart';
import 'package:life_journal/widgets/journal_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _journalEntries = [
    {
      "title": "A Walk in the Park",
      "snippet": "The weather was perfect today. I saw a dog playing fetch...",
      "date": "Nov 14, 2025",
      "mood": Icons.wb_sunny,
    },
  ];
  void _navigateToAddScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => AddEditScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _journalEntries.insert(0, result);
      });
    }
  }

  void _navigateToEditScreen(Map<String, dynamic> entry, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => AddEditScreen(journalEntry: entry)),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _journalEntries[index] = result;
      });
    }
  }

  //for showing contet menu
  void _showContextMenu(Offset tapPosition, int index) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    //show the menu ay the tap position
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 30, 30),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
    if (result == 'delete') {
      _shoeDeleteConfirmation(index);
    }
  }

  void _shoeDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete the journal?'),
        content: Text('Are you sure you want to delete the journal?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _journalEntries.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Journal Deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Journals"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings, color: Colors.black),
          ),
        ],
      ),
      body: _journalEntries.isEmpty
          ? Center(child: Text("No Entries yet!"))
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
              ),
              itemCount: _journalEntries.length,
              itemBuilder: (context, index) {
                final entry = _journalEntries[index];
                return JournalCard(
                  title: entry['title'],
                  snippet: entry['snippet'],
                  date: entry['date'],
                  moodIcon: entry['mood'],
                  onTap: () {
                    _navigateToEditScreen(entry, index);
                  },
                  onLongPress: (tapPosition) {
                    _showContextMenu(tapPosition, index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        child: Icon(Icons.add),
      ),
    );
  }
}
