import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'comps/widgets.dart';

class AnnouncementPage extends StatelessWidget {
  final List<Announcement> announcements = [
    Announcement(
      title: 'Announcement 1',
      description: 'This is the description of announcement 1.',
      imageUrl: 'https://example.com/image1.jpg',
    ),
    Announcement(
      title: 'Announcement 2',
      description: 'This is the description of announcement 2.',
      imageUrl: 'https://example.com/image2.jpg',
    ),
    Announcement(
      title: 'Announcement 3',
      description: 'This is the description of announcement 3.',
      imageUrl: 'https://example.com/image3.jpg',
    ),
  ];

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

drawer(context) {
  return Drawer(
    backgroundColor: Colors.indigo.shade400,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20),
        child: Theme(
          data: ThemeData.dark(),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(
                color: Colors.white,
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              ChatWidgets.announcements(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async => await FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
