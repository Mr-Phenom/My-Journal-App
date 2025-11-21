import 'package:flutter/material.dart';
import 'package:life_journal/screens/add_edit_screen.dart';
import 'package:life_journal/screens/journal_view_screen.dart';
import 'package:life_journal/services/database_helper.dart';
import 'package:life_journal/widgets/journal_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _journalEntries = [];
  var _isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _refreshJournal();
  }

  Future<void> _refreshJournal() async {
    setState(() {
      _isLoading = true;
    });
    final data = await DatabaseHelper.instance.readAllJournals();
    setState(() {
      _journalEntries = data;
      _isLoading = false;
    });
  }

  void _navigateToAddScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => AddEditScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final dbEntry = {
        'title': result['title'],
        'snippet': result['snippet'],
        'date': result['date'],
        'mood': (result['mood'] as IconData).codePoint,
        // 1. SAVE ACTUAL IMAGE PATH
        'image_path': result['image_path'] ?? '',
      };
      await DatabaseHelper.instance.create(dbEntry);
      _refreshJournal();
    }
  }

  void _navigateToViewScreen(Map<String, dynamic> entry, int index) async {
    final viewEntry = Map<String, dynamic>.from(entry);
    viewEntry['mood'] = IconData(entry['mood'], fontFamily: 'MaterialIcons');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => JournalViewScreen(entry: viewEntry)),
    );
    if (result != null && result is Map<String, dynamic>) {
      if (result['delete'] == true) {
        _refreshJournal();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal Deleted!'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final updateEntry = {
        'id': entry['id'],
        'title': result['title'],
        'snippet': result['snippet'],
        'date': result['date'],
        'mood': (result['mood'] as IconData).codePoint,
        // 2. UPDATE ACTUAL IMAGE PATH
        'image_path': result['image_path'] ?? '',
      };

      await DatabaseHelper.instance.update(updateEntry);
      _refreshJournal();
    }
  }

  //for showing contet menu
  void _showContextMenu(Offset tapPosition, int id) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    //show the menu ay the tap position
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx + 100, tapPosition.dy - 20, 30, 30),
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
      _shoeDeleteConfirmation(id);
    }
  }

  void _shoeDeleteConfirmation(int id) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.delete(id);
              _refreshJournal();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Journal Deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
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
                final moodIcon = IconData(
                  entry['mood'],
                  fontFamily: 'MaterialIcons',
                );
                return JournalCard(
                  title: entry['title'],
                  snippet: entry['snippet'],
                  date: entry['date'],
                  moodIcon: moodIcon,
                  onTap: () {
                    _navigateToViewScreen(entry, index);
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
