import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/comps/styles.dart';
import 'package:flutterfire_ui/auth.dart';
import '../groupPage.dart';
import 'animated-dialog.dart';

class ChatWidgets {
  static Widget card({title, time, subtitle, onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Card(
        elevation: 0,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(5),
          leading: const Padding(
            padding: EdgeInsets.all(0.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(time),
          ),
        ),
      ),
    );
  }

  static Widget circleProfile({onTap, name}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget messagesCard(bool check, message, time, {String? imageUrl}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (check) const Spacer(),
          if (!check)
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 10,
              child: Icon(
                Icons.person,
                size: 13,
                color: Colors.white,
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: Styles.messagesCardStyle(check),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Text(
                    '$message\n\n$time',
                    style:
                        TextStyle(color: check ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
          ),
          if (check)
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 10,
              child: Icon(
                Icons.person,
                size: 13,
                color: Colors.white,
              ),
            ),
          if (!check) const Spacer(),
        ],
      ),
    );
  }

  static Widget messageField({required onSubmit}) {
    final con = TextEditingController();

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: Styles.messageFieldCardStyle(),
      child: TextField(
        controller: con,
        decoration: Styles.messageTextFieldStyle(onSubmit: () {
          onSubmit(con);
        }),
      ),
    );
  }

  static Widget drawer(context) {
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

  static Widget searchBar(bool open) {
    return AnimatedDialog(
      height: open ? 800 : 0,
      width: open ? 400 : 0,
    );
  }

  static Widget announcements() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Card(
        elevation: 0,
        child: ListTile(
          title: const Text('Announcements'),
          subtitle: const Text('See what\'s new'),
          onTap: () {
            // TODO: Show announcements
          },
        ),
      ),
    );
  }

  static Widget searchField({Function(String)? onChange}) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: Styles.messageFieldCardStyle(),
      child: TextField(
        onChanged: onChange,
        decoration: Styles.searchTextFieldStyle(),
      ),
    );
  }
}

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Page'),
      ),
      body: const Center(
        child: Text('This is the announcement page'),
      ),
    );
  }
}

class GroupsHomePage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  GroupsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('GroupChats')
            .where('members', arrayContains: currentUser!.uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          List<QueryDocumentSnapshot> groupChats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groupChats.length,
            itemBuilder: (BuildContext context, int index) {
              QueryDocumentSnapshot groupChat = groupChats[index];
              String groupChatId = groupChat.id;
              List<dynamic> memberIds = groupChat['members'];
              List<String> selectedUserIds =
                  memberIds.map((id) => id.toString()).toList();
              String groupName =
                  ''; // Replace with the group name field from Firestore

              return ListTile(
                title: Text(groupName),
                subtitle: Text('Group Chat ID: $groupChatId'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupPage(
                        groupChatId: groupChatId,
                        selectedUserIds: selectedUserIds,
                        groupName: '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
