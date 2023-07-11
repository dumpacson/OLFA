import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class GroupPage extends StatefulWidget {
  final List<String> selectedUserIds;
  final String groupChatId;
  final String groupName;

  GroupPage({
    required this.selectedUserIds,
    required this.groupChatId,
    required this.groupName,
  });

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  TextEditingController _messageController = TextEditingController();
  TextEditingController _groupNameController = TextEditingController();
  List<String> memberIds = [];
  List<String> memberNames = [];
  String groupName = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    fetchMembers();
    fetchGroupName();
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

  Future<void> fetchGroupName() async {
    final groupChatDoc = await FirebaseFirestore.instance
        .collection('GroupChats')
        .doc(widget.groupChatId)
        .get();
    final groupName = groupChatDoc['groupName'];
    setState(() {
      this.groupName = groupName;
      _groupNameController.text = groupName;
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('GroupChats')
          .doc(widget.groupChatId)
          .collection('Messages')
          .add({
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'message': message,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
    }
  }

  void _submitGroupName() {
    setState(() {
      _isEditing = false;
      groupName = _groupNameController.text.trim();
      _groupNameController.text = groupName;
    });

    // Save the updated group name to Firestore
    FirebaseFirestore.instance
        .collection('GroupChats')
        .doc(widget.groupChatId)
        .update({'groupName': groupName});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _groupNameController,
                onSubmitted: (_) => _submitGroupName(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
              )
            : Text(groupName),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _groupNameController,
            onChanged: (value) {
              setState(() {
                groupName = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Group Name',
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('GroupChats')
                  .doc(widget.groupChatId)
                  .collection('Messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
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
                        alignment: memberIds.contains(senderId)
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: memberIds.contains(senderId)
                                ? Colors.blue
                                : Colors.grey,
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
