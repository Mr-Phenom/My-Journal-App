import 'dart:io';
import 'dart:convert'; // Needed for JSON encoding
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_journal/screens/pin_screen.dart';
import 'package:path_provider/path_provider.dart'; // Needed for persistent storage
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart'; // Needed for file naming

class AddEditScreen extends StatefulWidget {
  final Map<String, dynamic>? journalEntry;
  const AddEditScreen({super.key, this.journalEntry});

  @override
  State<AddEditScreen> createState() {
    return _AddEditScreenState();
  }
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  List<String> _selectedImagePaths = [];
  IconData _selectedMood = Icons.sentiment_very_satisfied;
  String _moodLabel = 'happy';

  bool _isLocked = false;

  final List<Map<String, dynamic>> _moodsList = [
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
    super.initState();

    if (widget.journalEntry != null) {
      _titleController.text = widget.journalEntry!['title'] ?? "";
      _textController.text = widget.journalEntry!['snippet'] ?? "";

      _isLocked = (widget.journalEntry!['isL_locked'] ?? 0) == 1;

      String? dbImages = widget.journalEntry!['image_path'];
      if (dbImages != null && dbImages.isNotEmpty) {
        try {
          // try to decode as a json file {'path1','path2'}
          List<dynamic> decoded = jsonDecode(dbImages);
          _selectedImagePaths = decoded.map((e) => e.toString()).toList();
        } catch (e) {
          // if fails, it is old single path so add to list
          _selectedImagePaths.add(dbImages);
        }
      }
      if (widget.journalEntry!.containsKey('mood') &&
          widget.journalEntry!['mood'] != null) {
        try {
          // Safely convert the integer back to an Icon
          int moodCode = widget.journalEntry!['mood'];
          _selectedMood = IconData(moodCode, fontFamily: 'MaterialIcons');

          // Find the matching label
          final moodMap = _moodsList.firstWhere(
            (m) => (m['icon'] as IconData).codePoint == _selectedMood.codePoint,
            orElse: () => {'label': 'Custom'},
          );
          _moodLabel = moodMap['label'];
        } catch (e) {
          // If anything goes wrong, fallback to Happy
          _selectedMood = Icons.sentiment_very_satisfied;
          _moodLabel = "Happy";
        }
      }
    }
  }

  void _toggleLock() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = prefs.containsKey('user_pin');

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

    // Verify PIN before changing setting
    if (mounted) {
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const PinScreen(isSetting: false)),
      );

      if (verified == true) {
        setState(() {
          _isLocked = !_isLocked;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLocked ? "Entry Secured" : "Entry Unlocked"),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Saving image to permanetly to app storage
  Future<String> _saveImageToAppDir(XFile pickedFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
    final File localImage = await File(
      pickedFile.path,
    ).copy('${directory.path}/$fileName');
    return localImage.path;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      String localPath = await _saveImageToAppDir(pickedFile);
      setState(() {
        _selectedImagePaths.add(localPath);
      });
    }
  }

  // Show modal to choose camera or gallery
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gellary'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(15),
          height: 400,
          child: Column(
            children: [
              Text("How are you feeling about this journal?"),
              SizedBox(height: 15),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                  ),
                  itemCount: _moodsList.length,
                  itemBuilder: (context, index) {
                    final mood = _moodsList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMood = mood['icon'];
                          _moodLabel = mood['label'];
                        });
                        Navigator.pop(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: (mood['color'] as Color)
                                .withOpacity(0.2),
                            child: Icon(mood['icon'], color: mood['color']),
                          ),
                          SizedBox(height: 4),
                          Text(mood['label'], overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSave() {
    final title = _titleController.text;
    final text = _textController.text;

    if (title.isEmpty && text.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final String formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(DateTime.now());

    String imagePathString = jsonEncode(_selectedImagePaths);

    final newEntry = {
      "title": title.isEmpty ? "Untitled" : title,
      "snippet": text,
      "date": formattedDate,
      "mood": _selectedMood,
      'image_path': imagePathString,
    };

    Navigator.pop(context, newEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.journalEntry != null
            ? Text("Edit Journal")
            : Text('New Journal'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            onPressed: _toggleLock,
            icon: _isLocked
                ? Icon(Icons.lock_open, color: Colors.green)
                : Icon(Icons.lock, color: Colors.red),
          ),
          IconButton(
            onPressed: _onSave,
            icon: Icon(Icons.save, color: Colors.black87),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Whats on your mind?",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              minLines: 10,
              keyboardType: TextInputType.multiline,
            ),

            SizedBox(height: 18),
            if (_selectedImagePaths != null)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (ctx, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRect(
                            child: Image.file(
                              File(_selectedImagePaths[index]),
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImagePaths.removeAt(index);
                                });
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.close),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  itemCount: _selectedImagePaths.length,
                ),
              ),
            if (_selectedImagePaths != null) SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: _showMoodPicker,
                      icon: Icon(_selectedMood, size: 30),
                    ),
                    Text(_moodLabel),
                  ],
                ),
                SizedBox(width: 24),
                Column(
                  children: [
                    IconButton(
                      onPressed: _showImageSourceActionSheet,
                      icon: Icon(Icons.image, size: 30),
                    ),
                    Text("Image"),
                  ],
                ),
                SizedBox(width: 24),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        /*To do Sticker picker*/
                      },
                      icon: Icon(Icons.star, size: 30),
                    ),
                    Text("Sticker"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
