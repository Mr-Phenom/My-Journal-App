import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.journalEntry != null) {
      _titleController.text = widget.journalEntry!['title'];
      _textController.text = widget.journalEntry!['snippet'];
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
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

    final newEntry = {
      "title": title.isEmpty ? "Untitled" : title,
      "snippet": text,
      "date": formattedDate,
      "mood": Icons.mood,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        /*To do mood picker*/
                      },
                      icon: Icon(Icons.mood),
                    ),
                    Text("Mood"),
                  ],
                ),
                SizedBox(width: 24),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        /*To do Image picker*/
                      },
                      icon: Icon(Icons.image),
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
                      icon: Icon(Icons.star),
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
