import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:life_journal/screens/add_edit_screen.dart';
import 'package:life_journal/screens/journal_view_screen.dart';
import 'package:life_journal/screens/pin_screen.dart';
import 'package:life_journal/screens/settings_screen.dart';
import 'package:life_journal/services/database_helper.dart';
import 'package:life_journal/widgets/journal_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _allData = [];

  var _isLoading = true;
  var _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  String _sortOrder = 'Newest';
  String _imagefilter = 'All';
  List<int> _selectedMoodFilters = [];

  // We need this list here just to generate the Filter UI chips
  final List<Map<String, dynamic>> _moodOptions = [
    {
      'label': 'Happy',
      'icon': Icons.sentiment_very_satisfied,
      'color': Colors.amber,
    },
    {
      'label': 'Sad',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.blueGrey,
    },
    {'label': 'Angry', 'icon': Icons.mood_bad, 'color': Colors.red},
    {'label': 'Depressed', 'icon': Icons.cloud_off, 'color': Colors.indigo},
    {'label': 'Disgusted', 'icon': Icons.sick, 'color': Colors.green},
    {'label': 'Nostalgia', 'icon': Icons.history_edu, 'color': Colors.brown},
    {
      'label': 'Pity',
      'icon': Icons.volunteer_activism,
      'color': Colors.pinkAccent,
    },
    {
      'label': 'Pretty',
      'icon': Icons.face_retouching_natural,
      'color': Colors.purpleAccent,
    },
    {'label': 'Powerful', 'icon': Icons.bolt, 'color': Colors.orangeAccent},
    {
      'label': 'Superior',
      'icon': Icons.emoji_events,
      'color': Colors.deepOrange,
    },
    {'label': 'Inferior', 'icon': Icons.broken_image, 'color': Colors.grey},
    {'label': 'Fun', 'icon': Icons.celebration, 'color': Colors.teal},
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _refreshJournal();
  }

  Future<void> _refreshJournal() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> data;
    String query = _searchController.text;

    // If there is text in the search bar, use the Search function
    if (query.isNotEmpty) {
      data = await DatabaseHelper.instance.searchJournals(query);
    } else {
      // Otherwise, get everything
      data = await DatabaseHelper.instance.readAllJournals();
    }

    _allData = data;
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filteredList = List.from(_allData);
    // 1.Image filter
    if (_selectedMoodFilters.isNotEmpty) {
      filteredList = filteredList.where((entry) {
        return _selectedMoodFilters.contains(entry['mood']);
      }).toList();
    }

    // 2. Filter by Image
    if (_imagefilter != 'All') {
      filteredList = filteredList.where((entry) {
        bool hasImage = false;
        String? imgStr = entry['image_path'];
        if (imgStr != null && imgStr.isNotEmpty) {
          try {
            // Check if it's a list and has items
            List decoded = jsonDecode(imgStr);
            if (decoded.isNotEmpty) hasImage = true;
          } catch (e) {
            // Check if it's a single path string
            hasImage = true;
          }
        }

        if (_imagefilter == 'Has Image') return hasImage;
        if (_imagefilter == 'Text Only') return !hasImage;
        return true;
      }).toList();
    }

    // 3. Sort by Date
    // We must parse "MMM d, yyyy" to compare dates correctly
    DateFormat format = DateFormat("MMM d, yyyy");

    filteredList.sort((a, b) {
      DateTime dateA;
      DateTime dateB;
      try {
        dateA = format.parse(a['date']);
      } catch (e) {
        dateA = DateTime(1900);
      }
      try {
        dateB = format.parse(b['date']);
      } catch (e) {
        dateB = DateTime(1900);
      }

      if (_sortOrder == 'Newest') {
        return dateB.compareTo(dateA); // Descending
      } else {
        return dateA.compareTo(dateB); // Ascending
      }
    });

    setState(() {
      _journalEntries = filteredList;
      _isLoading = false;
    });
  }

  // 3. MANAGE PIN (Set or Change)
  void _managePin() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasPin = prefs.containsKey('user_pin');

    if (hasPin) {
      // Change PIN: Must verify old one first
      if (mounted) {
        final verified = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => const PinScreen(isSetting: false),
          ),
        );
        if (verified == true && mounted) {
          // Old PIN good, set new one
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => const PinScreen(isSetting: true),
            ),
          );
        }
      }
    } else {
      // Set New PIN
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const PinScreen(isSetting: true)),
        );
      }
    }
  }

  // 4. NAVIGATE (With Security Check)
  void _handleCardTap(Map<String, dynamic> entry, int index) async {
    bool isLocked = (entry['is_locked'] ?? 0) == 1;

    if (isLocked) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('user_pin')) {
        // Ask for PIN
        if (mounted) {
          final verified = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => const PinScreen(isSetting: false),
            ),
          );
          if (verified != true) return; // Wrong PIN or Cancelled
        }
      } else {
        // Locked but no PIN set? Open it (or warn user)
        // Standard behavior: If lock exists but global PIN was cleared, maybe warn?
        // For now, let's allow open to avoid lockout.
      }
    }
    // If unlocked or verified, proceed
    _navigateToViewScreen(entry, index);
  }

  // --- FILTER UI BOTTOM SHEET ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to grow
      builder: (context) {
        // Use StatefulWidget inside sheet to update chips dynamically
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height:
                  MediaQuery.of(context).size.height * 0.7, // 70% screen height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter & Sort",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Reset Logic
                          setState(() {
                            _sortOrder = 'Newest';
                            _imagefilter = 'All';
                            _selectedMoodFilters.clear();
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                  const Divider(),

                  // 1. Sort Section
                  const Text(
                    "Sort By Date",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Newest First"),
                        selected: _sortOrder == 'Newest',
                        onSelected: (bool selected) {
                          setSheetState(() => _sortOrder = 'Newest');
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("Oldest First"),
                        selected: _sortOrder == 'Oldest',
                        onSelected: (bool selected) {
                          setSheetState(() => _sortOrder = 'Oldest');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Image Filter Section
                  const Text(
                    "Content",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Has Image', 'Text Only'].map((option) {
                      return ChoiceChip(
                        label: Text(option),
                        selected: _imagefilter == option,
                        onSelected: (bool selected) {
                          if (selected)
                            setSheetState(() => _imagefilter = option);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 3. Mood Filter Section
                  const Text(
                    "Moods",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        children: _moodOptions.map((mood) {
                          final int code = (mood['icon'] as IconData).codePoint;
                          final bool isSelected = _selectedMoodFilters.contains(
                            code,
                          );

                          return FilterChip(
                            label: Text(mood['label']),
                            avatar: Icon(
                              mood['icon'],
                              size: 16,
                              color: mood['color'],
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setSheetState(() {
                                if (selected) {
                                  _selectedMoodFilters.add(code);
                                } else {
                                  _selectedMoodFilters.remove(code);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters(); // Apply logic
                        Navigator.pop(context); // Close sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Apply Filters"),
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

  void _onSearchChanged(String query) {
    _refreshJournal();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _refreshJournal();
      }
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.black),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search journals...',
                  hintStyle: TextStyle(color: Colors.black),
                  border: InputBorder.none,
                ),
              )
            : Text("My Journals"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
          ),
          if (!_isSearching)
            IconButton(
              onPressed: _showFilterSheet, // OPEN THE SHEET
              // Change icon color if filters are active so user knows
              icon: Icon(
                Icons.filter_list,
                color:
                    (_selectedMoodFilters.isNotEmpty ||
                        _imagefilter != 'All' ||
                        _sortOrder != 'Newest')
                    ? Colors
                          .white // Active (highlighted)
                    : Colors.black, // Inactive
              ),
            ),
          if (!_isSearching)
            IconButton(
              onPressed: _managePin,
              icon: const Icon(Icons.security, color: Colors.black),
              tooltip: "Set/Change PIN",
            ),
          if (!_isSearching)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings, color: Colors.black),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _journalEntries.isEmpty
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
                bool isLocked = (entry['is_locked'] ?? 0) == 1;
                return JournalCard(
                  title: entry['title'],

                  snippet: isLocked ? "🔒 Secured Entry" : entry['snippet'],
                  date: entry['date'],
                  moodIcon: moodIcon,
                  onTap: () {
                    _handleCardTap(entry, index);
                  },
                  onLongPress: (tapPosition) {
                    _showContextMenu(tapPosition, entry['id']);
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
