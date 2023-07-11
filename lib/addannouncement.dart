import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAnnouncement extends StatefulWidget {
  @override
  _AddAnnouncementState createState() => _AddAnnouncementState();
}

class _AddAnnouncementState extends State<AddAnnouncement> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();
    String imageUrl = _imageUrlController.text.trim();

    // Create a new document in the 'announcements' collection
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
      });

      // Clear the text fields after successful submission
      _titleController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();

      // Show a snackbar or navigate to a different page after submission if desired
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement submitted!')),
      );
    } catch (error) {
      // Handle any error that occurs during saving to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting announcement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Announcement'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: submitForm,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
