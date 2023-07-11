import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final firestore = FirebaseFirestore.instance;
  bool open = false;
  List<String> selectedUserIds = [];

  void initState() {
    super.initState();
    updateAvailability();
  }

  void updateAvailability() {
    // Perform the availability update logic
    // Replace this with your actual implementation
    print('Updating availability...');
  }

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
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
  
  List<String> allMemberIds = [...selectedUserIds]; // Include selected user IDs
  allMemberIds.add(FirebaseAuth.instance.currentUser!.uid); // Include current user ID

  // Create a new group chat document in Firestore
  final groupChatRef = await firestore.collection('GroupChats').add({
    'members': allMemberIds,
    // Add any additional fields you want for the group chat document
  });

  // Get the newly created group chat ID
  final groupChatId = groupChatRef.id;

  // Create a new message collection for the group chat
  await groupChatRef.collection('Messages').add({
    'senderId': FirebaseAuth.instance.currentUser!.uid,
    'message': 'Welcome to the group chat!', // Add a welcome message or any initial message
    'timestamp': DateTime.now(),
  });

  // Clear the selected user IDs
  setState(() {
    selectedUserIds.clear();
  });

  print('Group chat created with ID: $groupChatId');

  // Navigate to the group chat page with the group chat ID
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return GroupPage(
          selectedUserIds: selectedUserIds,
          groupChatId: groupChatId,
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
      drawer: drawer(),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                          child: Text(
                            'Recent Users',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 80,
                          child: StreamBuilder(
                            stream: firestore.collection('Rooms').snapshots(),
                            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                              List data = !snapshot.hasData
                                  ? []
                                  : snapshot.data!.docs
                                  .where((element) => element['users'].toString().contains(FirebaseAuth.instance.currentUser!.uid))
                                  .toList();
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: data.length,
                                itemBuilder: (context, i) {
                                  List users = data[i]['users'];
                                  var friend = users.where((element) => element != FirebaseAuth.instance.currentUser!.uid);
                                  var user = friend.isNotEmpty ? friend.first : users.where((element) => element == FirebaseAuth.instance.currentUser!.uid).first;
                                  return FutureBuilder(
                                    future: firestore.collection('Users').doc(user).get(),
                                    builder: (context, AsyncSnapshot snap) {
                                      return !snap.hasData
                                          ? Container()
                                          : circleProfile(snap.data['name']);
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Text(
                            'Contacts',
                            style: TextStyle(fontSize: 20, color: Colors.indigo),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: StreamBuilder(
                              stream: firestore.collection('Rooms').snapshots(),
                              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                List data = !snapshot.hasData
                                    ? []
                                    : snapshot.data!.docs
                                    .where((element) => element['users'].toString().contains(FirebaseAuth.instance.currentUser!.uid))
                                    .toList();
                                return ListView.builder(
                                  itemCount: data.length,
                                  itemBuilder: (context, i) {
                                    List users = data[i]['users'];
                                    var friend = users.where((element) => element != FirebaseAuth.instance.currentUser!.uid);
                                    var user = friend.isNotEmpty ? friend.first : users.where((element) => element == FirebaseAuth.instance.currentUser!.uid).first;
                                    return FutureBuilder(
                                      future: firestore.collection('Users').doc(user).get(),
                                      builder: (context, AsyncSnapshot snap) {
                                        return !snap.hasData
                                            ? Container()
                                            : card(snap.data['name'], data[i]['last_message'], DateFormat('hh:mm a').format(data[i]['last_message_time'].toDate()));
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
            searchBar(open),
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: () {},
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

  Widget searchBar(bool open) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      top: 10,
      right: open ? 0 : MediaQuery.of(context).size.width,
      width: MediaQuery.of(context).size.width * 0.75,
      child: GestureDetector(
        onTap: () {
          setState(() {
            open = !open;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.indigo,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Item 1'),
            onTap: () {
              // Handle item 1 tap
            },
          ),
          ListTile(
            title: Text('Item 2'),
            onTap: () {
              // Handle item 2 tap
            },
          ),
        ],
      ),
    );
  }

  Widget circleProfile(String name) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            child: Icon(
              Icons.person,
              color: Colors.grey.shade800,
              size: 30,
            ),
          ),
          SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget card(String title, String subtitle, String time) {
    return InkWell(
      onTap: () {
        // Handle card tap
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: Colors.grey.shade800,
                size: 30,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupPage extends StatefulWidget {
  final List<String> selectedUserIds;
  final String groupChatId;

  GroupPage({
    required this.selectedUserIds,
    required this.groupChatId,
  });

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  TextEditingController _messageController = TextEditingController();
  List<String> memberIds = [];
  List<String> memberNames = [];

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    final snapshot = await FirebaseFirestore.instance.collection('Users').get();
    final List<String> fetchedMemberIds = [];
    final List<String> fetchedMemberNames = [];
    snapshot.docs.forEach((doc) {
      final data = doc.data();
      final memberId = doc.id;
      final memberName = data['name'] ?? '';
      if (widget.selectedUserIds.contains(memberId)) {
        fetchedMemberIds.add(memberId);
        fetchedMemberNames.add(memberName);
      }
    });
    setState(() {
      memberIds = fetchedMemberIds;
      memberNames = fetchedMemberNames;
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      FirebaseFirestore.instance.collection('GroupChats').doc(widget.groupChatId).collection('Messages').add({
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'message': message,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('GroupChats')
                  .doc(widget.groupChatId)
                  .collection('Messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                List<QueryDocumentSnapshot> messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    String senderId = messages[index]['senderId'];
                    String message = messages[index]['message'];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: memberIds.contains(senderId) ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: memberIds.contains(senderId) ? Colors.blue : Colors.grey,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            message,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

