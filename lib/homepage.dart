import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Logics/functions.dart';
import 'package:flutter_chat_app/chatpage.dart';
import 'package:intl/intl.dart';
import 'comps/styles.dart';
import 'comps/widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade400,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade400,
        title: const Text('Chat App'),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: ChatWidgets.drawer(context),
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            'Contacts',
                            style: Styles.h1().copyWith(color: Colors.indigo),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: StreamBuilder(
                                stream:
                                    firestore.collection('Rooms').snapshots(),
                                builder: (context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  List data = !snapshot.hasData
                                      ? []
                                      : snapshot.data!.docs
                                          .where((element) => element['users']
                                              .toString()
                                              .contains(FirebaseAuth.instance
                                                  .currentUser!.uid))
                                          .toList();
                                  return ListView.builder(
                                    itemCount: data.length,
                                    itemBuilder: (context, i) {
                                      List users = data[i]['users'];
                                      var friend = users.where(
                                          (element) =>
                                              element !=
                                              FirebaseAuth
                                                  .instance.currentUser!.uid);
                                      var user = friend.isNotEmpty
                                          ? friend.first
                                          : users.where((element) =>
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
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            return ChatPage(
                                                              id: user,
                                                              name: snap.data[
                                                                  'name'],
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                          });
                                    },
                                  );
                                }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ChatWidgets.searchBar(open)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnnouncementPage()),
          );
        },
        child: Icon(
          IconData(0xee78, fontFamily: 'MaterialIcons'),
        ),
        backgroundColor: Colors.indigo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class AnnouncementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcement Page'),
      ),
      body: Center(
        child: Text('This is the announcement page'),
      ),
    );
  }
}
