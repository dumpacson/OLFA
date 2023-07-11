import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/addannouncement.dart';
import 'package:flutter_chat_app/comps/widgets.dart';
import 'package:flutter_chat_app/homepage.dart';


class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

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
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final announcement = Announcement(
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
      );
      fetchedAnnouncements.add(announcement);
    }
    setState(() {
      announcements = fetchedAnnouncements;
    });
  }

  void addAnnouncementPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAnnouncement(),
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
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MaterialButton(
                    minWidth: 130,
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const announcement.AnnouncementPage(),
                      //   ),
                      // );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.announcement,
                          color: Colors.indigo.shade400,
                        ),
                        Text(
                          'Announcement',
                          style: TextStyle(color:Colors.indigo.shade400),
                        )
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 130,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupsHomePage(), // Replace GroupsHomePage with the actual group home page widget
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          color: Colors.indigo.shade400,
                        ),
                        Text(
                          'Groups',
                          style: TextStyle(color:Colors.indigo.shade400),
                        ),
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 130,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyHomePage(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          color: Colors.indigo.shade400,
                        ),
                        Text(
                          'Chats',
                          style: TextStyle(color: Colors.indigo.shade400),
                        ),
                      ],
                    ),
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
