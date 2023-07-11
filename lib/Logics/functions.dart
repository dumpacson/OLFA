// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;


class Functions {
  static void updateAvailability() {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final data = {
      'name': auth.currentUser!.displayName ?? auth.currentUser!.email,
      'date_time': DateTime.now(),
      'email': auth.currentUser!.email,
    };
    try {
      firestore.collection('Users').doc(auth.currentUser!.uid).set(data);
    } catch (e) {
      print(e);
    }
  }

  static void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  static void saveToken(String token) async {
    await FirebaseFirestore.instance.collection("UserTokens").doc("hadi").set({
      'token': token,
    });
  }
  
  static void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAA-j1OXII:APA91bFNTjaKU-sIOfeyJCPPRADsG1i9WgkJDxKIzRcpwL9nDIdPhL6Zv4-E0LB3XamWpj9nHtpl6NGYe9Q4yNg8v7PoWjHB6UgSX2b7Xr2oNfJBW-KAG1KDjjnRZWF15CGdIGj6H1Dl',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            "notification": <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "dbfood"
            },
            "to": token,
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("error push notification");
      }
    }
  }

}
