import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/addannouncement.dart';

class AnnouncementPage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<Announcement> announcements = [];

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    final snapshot = await FirebaseFirestore.instance.collection('announcements').get();
    final List<Announcement> fetchedAnnouncements = [];
    snapshot.docs.forEach((doc) {
      final data = doc.data();
      final announcement = Announcement(
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
      );
      fetchedAnnouncements.add(announcement);
    });
    setState(() {
      announcements = fetchedAnnouncements;
    });
  }

  void addAnnouncementPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAnnouncement(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          Announcement announcement = announcements[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                Image.network(
                  announcement.imageUrl,
                  fit: BoxFit.cover,
                ),
                ListTile(
                  title: Text(announcement.title),
                  subtitle: Text(announcement.description),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addAnnouncementPage,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class Announcement {
  final String title;
  final String description;
  final String imageUrl;

  Announcement({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}
