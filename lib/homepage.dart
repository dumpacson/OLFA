import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Logics/functions.dart';
import 'package:flutter_chat_app/chatpage.dart';
import 'package:intl/intl.dart';
import 'comps/styles.dart';
import 'comps/widgets.dart';
import 'package:flutter_chat_app/announcement.dart' as Announcement;
import 'groupPage.dart'; // Import groupPage.dart

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    Functions.updateAvailability();
    super.initState();
  }

  final firestore = FirebaseFirestore.instance;
  bool open = false;
  List<String> selectedUserIds = [];

  void _showUserListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Users'),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('Users').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: documents.length,
                      itemBuilder: (BuildContext context, int index) {
                        var user = documents[index];
                        var userId = user.id;
                        var userName = user['name'];
                        var isSelected = selectedUserIds.contains(userId);

                        return ListTile(
                          title: Text(userName),
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedUserIds.add(userId);
                                } else {
                                  selectedUserIds.remove(userId);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedUserIds.remove(userId);
                              } else {
                                selectedUserIds.add(userId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                setState(() {
                  selectedUserIds.clear();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                // Process the selected users
                // selectedUserIds contains the selected user IDs
                // You can perform your desired action here, such as creating a new group chat with the selected users
                // Once the action is complete, you can clear the selectedUserIds if needed

                if (selectedUserIds.length >= 2) {
                  _createGroupChat();
                }

                setState(() {
                  selectedUserIds.clear();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _createGroupChat() async {
    print('Creating group chat...');

    List<String> allMemberIds = [
      ...selectedUserIds
    ]; // Include selected user IDs
    allMemberIds
        .add(FirebaseAuth.instance.currentUser!.uid); // Include current user ID

    // Create a new group chat document in Firestore
    final groupChatRef = await firestore.collection('GroupChats').add({
      'members': allMemberIds,
      // Add any additional fields you want for the group chat document
    });

    // Get the newly created group chat ID
    final groupChatId = groupChatRef.id;
    print('Group chat ID: $groupChatId');

    // Create a new message collection for the group chat
    await groupChatRef.collection('Messages').add({
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'message':
          'Welcome to the group chat!', // Add a welcome message or any initial message
      'timestamp': DateTime.now(),
    });

    // Clear the selected user IDs
    setState(() {
      selectedUserIds.clear();
    });

    print('Group chat created successfully');

    // Navigate to the group chat page with the group chat ID
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return GroupPage(
            selectedUserIds: selectedUserIds,
            groupChatId: groupChatId,
            groupName: '',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade400,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade400,
        title: const Text('Chat App'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GroupsHomePage(), // Replace GroupsHomePage with the actual group home page widget
                ),
              );
            },
            icon: Icon(
              Icons.group,
              size: 30,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: () {
                setState(() {
                  open = !open;
                });
              },
              icon: Icon(
                open ? Icons.close_rounded : Icons.search_rounded,
                size: 30,
              ),
            ),
          )
        ],
      ),
      drawer: ChatWidgets.drawer(context),
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.all(0),
                  child: Container(
                    color: Colors.indigo.shade400,
                    padding: const EdgeInsets.all(8),
                    height: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 10),
                          child: Text(
                            'Recent Users',
                            style: Styles.h1(),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 80,
                          child: StreamBuilder(
                            stream: firestore.collection('Rooms').snapshots(),
                            builder: (context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              List data = !snapshot.hasData
                                  ? []
                                  : snapshot.data!.docs
                                      .where((element) => element['users']
                                          .toString()
                                          .contains(FirebaseAuth
                                              .instance.currentUser!.uid))
                                      .toList();
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.length,
                                itemBuilder: (context, i) {
                                  List users = data[i]['users'];
                                  var friend = users.where((element) =>
                                      element !=
                                      FirebaseAuth.instance.currentUser!.uid);
                                  var user = friend.isNotEmpty
                                      ? friend.first
                                      : users
                                          .where((element) =>
                                              element ==
                                              FirebaseAuth
                                                  .instance.currentUser!.uid)
                                          .first;
                                  return FutureBuilder(
                                    future: firestore
                                        .collection('Users')
                                        .doc(user)
                                        .get(),
                                    builder: (context, AsyncSnapshot snap) {
                                      return !snap.hasData
                                          ? Container()
                                          : ChatWidgets.circleProfile(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) {
                                                      return ChatPage(
                                                        id: user,
                                                        name: snap.data['name'],
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                              name: snap.data['name'],
                                            );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: Styles.friendsBox(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Text(
                            'Chats',
                            style: Styles.h1().copyWith(color: Colors.indigo),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: StreamBuilder(
                              stream: firestore.collection('Rooms').snapshots(),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                List data = !snapshot.hasData
                                    ? []
                                    : snapshot.data!.docs
                                        .where((element) => element['users']
                                            .toString()
                                            .contains(FirebaseAuth
                                                .instance.currentUser!.uid))
                                        .toList();
                                return ListView.builder(
                                  itemCount: data.length,
                                  itemBuilder: (context, i) {
                                    List users = data[i]['users'];
                                    var friend = users.where((element) =>
                                        element !=
                                        FirebaseAuth.instance.currentUser!.uid);
                                    var user = friend.isNotEmpty
                                        ? friend.first
                                        : users
                                            .where((element) =>
                                                element ==
                                                FirebaseAuth
                                                    .instance.currentUser!.uid)
                                            .first;
                                    return FutureBuilder(
                                      future: firestore
                                          .collection('Users')
                                          .doc(user)
                                          .get(),
                                      builder: (context, AsyncSnapshot snap) {
                                        return !snap.hasData
                                            ? Container()
                                            : ChatWidgets.card(
                                                title: snap.data['name'],
                                                subtitle: data[i]
                                                    ['last_message'],
                                                time: DateFormat('hh:mm a')
                                                    .format(data[i][
                                                            'last_message_time']
                                                        .toDate()),
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return ChatPage(
                                                          id: user,
                                                          name:
                                                              snap.data['name'],
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ChatWidgets.searchBar(open),
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Announcement.AnnouncementPage(),
                    ),
                  );
                },
                child: Icon(
                  Icons.announcement,
                ),
                backgroundColor: Colors.indigo,
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showUserListDialog,
                child: Icon(
                  Icons.add,
                ),
                backgroundColor: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
