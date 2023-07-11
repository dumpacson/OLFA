// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/Logics/functions.dart';
import 'package:flutter_chat_app/chatpage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'comps/styles.dart';
import 'comps/widgets.dart';
import 'package:flutter_chat_app/announcement.dart' as announcement;
import 'groupPage.dart'; // Import groupPage.dart

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? mtoken = "";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int currentTab =0;
  final List<Widget> screens = [
    const AnnouncementPage(),
  ];

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = const AnnouncementPage();

  @override
  void initState() {
    super.initState();
    Functions.updateAvailability();
    Functions.requestPermission();
    getToken();
    initInfo();
  }

  initInfo(){
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitialize = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification : (String? payload) async {
      try{
        if(payload != null && payload.isNotEmpty) {
          // Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
          //   return ChatPage(id info: payload.toString());
          // }
          // ));
        } else {
        }
      }catch (e) {
      }
      return;
    });
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      print (" . . . . . . . . . . . . . . ....onMessage. . . . . . . . . . . . . . . .");
      print ("onMessage: ${message.notification?.title}/${message.notification?.body}}");
      
      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(), htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(), htmlFormatContentTitle: true,
      );
      AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'dbfood', 'dbfood', importance: Importance.high,
        styleInformation: bigTextStyleInformation, priority: Priority.high, playSound: true,
      );
      NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics,
      iOS: const IOSNotificationDetails()
      );
      await flutterLocalNotificationsPlugin.show(0, message.notification?.title,
      message.notification?.body, platformChannelSpecifics,
      payload: message.data['body']);
    });
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then(
      (token) {
        setState(() {
          mtoken = token;
          print("My token is $mtoken");
        });
        Functions.saveToken(token!);
      },
    );
  }
  
  final firestore = FirebaseFirestore.instance;
  bool open = false;
  List<String> selectedUserIds = [];

  void _showUserListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Users'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('Users').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
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
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  selectedUserIds.clear();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
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
      'id': 'Mahallah Faruq',
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
    // ignore: use_build_context_synchronously
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return GroupPage(
            selectedUserIds: selectedUserIds,
            groupChatId: groupChatRef.id,
            groupName: 'Mahallah Faruq',
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
          ],
        ),
      ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const announcement.AnnouncementPage(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.announcement,
                          color: currentTab == 0 ? Colors.indigo.shade400 : Colors.grey,
                        ),
                        Text(
                          'Announcement',
                          style: TextStyle(color: currentTab == 0 ?  Colors.indigo.shade400 : Colors.grey),
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
                          color: currentTab == 0 ? Colors.indigo.shade400 : Colors.grey,
                        ),
                        Text(
                          'Groups',
                          style: TextStyle(color: currentTab == 0 ?  Colors.indigo.shade400 : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  MaterialButton(
                    minWidth: 130,
                    onPressed: _showUserListDialog,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: currentTab == 0 ? Colors.indigo.shade400 : Colors.grey,
                        ),
                        Text(
                          'New Group',
                          style: TextStyle(color: currentTab == 0 ?  Colors.indigo.shade400 : Colors.grey),
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
