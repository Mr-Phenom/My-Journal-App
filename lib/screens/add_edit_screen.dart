import 'dart:io';
import 'dart:convert'; // Needed for JSON encoding
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // Needed for persistent storage
import 'package:path/path.dart' as path; // Needed for file naming

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

  @override
  void initState() {
    super.initState();

    if (widget.journalEntry != null) {
      _titleController.text = widget.journalEntry!['title'];
      _textController.text = widget.journalEntry!['snippet'];

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
      "mood": Icons.mood,
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
            onPressed: _onSave,
            icon: Icon(Icons.save, color: Colors.black12),
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
                      onPressed: () {
                        /*To do mood picker*/
                      },
                      icon: Icon(Icons.mood, size: 30),
                    ),
                    Text("Mood"),
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
