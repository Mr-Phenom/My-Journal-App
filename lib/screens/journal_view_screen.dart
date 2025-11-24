import 'package:flutter/material.dart';
import 'package:life_journal/screens/add_edit_screen.dart';
import 'package:life_journal/services/database_helper.dart';
import 'package:life_journal/screens/pin_screen.dart'; // 1. Import PIN Screen
import 'package:shared_preferences/shared_preferences.dart'; // 2. Import SharedPrefs
import 'dart:io';
import 'dart:convert';

class JournalViewScreen extends StatefulWidget {
  final Map<String, dynamic> entry;
  const JournalViewScreen({super.key, required this.entry});

  @override
  State<StatefulWidget> createState() {
    return _JournalViewState();
  }
}

class _JournalViewState extends State<JournalViewScreen> {
  bool _isLocked = false;
  late Map<String, dynamic> currentEntry;
  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadEntry(widget.entry);
  }

  void _loadEntry(Map<String, dynamic> entry) {
    // Create a mutable copy of the data so we can update it locally
    currentEntry = Map<String, dynamic>.from(entry);

    // 3. Load the initial lock state
    _isLocked = (currentEntry['is_locked'] ?? 0) == 1;

    imagePaths = [];
    String? dbImages = entry['image_path'];
    if (dbImages != null && dbImages.isNotEmpty) {
      try {
        List<dynamic> decode = jsonDecode(dbImages);
        imagePaths = decode.map((e) => e.toString()).toList();
      } catch (e) {
        imagePaths.add(dbImages);
      }
    }
  }

  // 4. NEW: Logic to Lock/Unlock this specific entry
  void _toggleLock() async {
    // Check if Global PIN exists
    final prefs = await SharedPreferences.getInstance();
    bool hasPin = prefs.containsKey('user_pin');

    if (!hasPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please set a PIN in the Home Screen first!"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Verify PIN
    if (mounted) {
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const PinScreen(isSetting: false)),
      );

      if (verified == true) {
        // Toggle state
        bool newStatus = !_isLocked;

        // Update Database
        // We create a map with the updated lock status to send to DB
        final updateEntry = Map<String, dynamic>.from(currentEntry);
        updateEntry['is_locked'] = newStatus ? 1 : 0;

        // IMPORTANT: Convert IconData back to int for Database if needed
        // (Assuming database_helper expects the integer code)
        if (updateEntry['mood'] is IconData) {
          updateEntry['mood'] = (updateEntry['mood'] as IconData).codePoint;
        }

        await DatabaseHelper.instance.update(updateEntry);

        // Update UI
        setState(() {
          _isLocked = newStatus;
          currentEntry['is_locked'] = newStatus
              ? 1
              : 0; // Update local data for PopScope
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus ? "Entry Locked" : "Entry Unlocked"),
            ),
          );
        }
      }
    }
  }

  void _navigateToEdit() async {
    // Security Check before editing
    if (_isLocked) {
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const PinScreen(isSetting: false)),
      );
      if (verified != true) return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddEditScreen(journalEntry: currentEntry),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _loadEntry(result);
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
              Navigator.pop(ctx);
              await DatabaseHelper.instance.delete(currentEntry['id']);
              if (mounted) {
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
        // Pass the currentEntry (with potentially updated lock status) back to Home
        Navigator.pop(context, currentEntry);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Journal"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            // 5. NEW: Lock Button
            IconButton(
              onPressed: _toggleLock,
              icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
              color: _isLocked
                  ? Colors.redAccent
                  : Colors.white, // Red if locked
              tooltip: 'Toggle Lock',
            ),
            IconButton(
              onPressed: _navigateToEdit,
              icon: const Icon(Icons.edit),
              color: Colors.white,
            ),
            IconButton(
              onPressed: _deleteEntry,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
            const SizedBox(width: 9),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      currentEntry['date'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Mood: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        currentEntry['mood'] is int
                            ? IconData(
                                currentEntry['mood'],
                                fontFamily: 'MaterialIcons',
                              )
                            : currentEntry['mood'],
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentEntry['title'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                currentEntry['snippet'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              if (imagePaths.isNotEmpty)
                Column(
                  children: imagePaths.map((path) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Image ${imagePaths.indexOf(path) + 1}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
