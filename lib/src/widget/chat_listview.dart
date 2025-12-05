import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';


class ClientChatScreen extends StatefulWidget {
  final Room room;

  const ClientChatScreen({Key? key, required this.room}) : super(key: key);

  @override
  _ClientChatScreenState createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  final DatabaseReference messagesRef =
  FirebaseDatabase.instance.ref().child('livekit_messages');

  final List<Map<String, String>> _messages = [];

  StreamSubscription<DatabaseEvent>? _firebaseListener;

  @override
  void initState() {
    super.initState();

    // ✅ Listen to Firebase in realtime
    _listenToFirebaseMessages();
  }

  // void _addMessage(String sender, String message) {
  //   setState(() {
  //     _messages.add({'sender': sender, 'message': message});
  //   });
  // }

  void _addMessage(String sender, String message) {
    bool exists = _messages.any((m) =>
    m['sender'] == sender &&
        m['message'] == message);

    if (!exists) {
      setState(() {
        _messages.add({'sender': sender, 'message': message});
      });
    }
  }


  void _listenToFirebaseMessages() {
    // ✅ Only listen — no .once()
    _firebaseListener = messagesRef.onChildAdded.listen((event) {
      final value = event.snapshot.value as Map?;
      if (value != null) {
        final sender = value['senderId'] ?? 'host';
        final message = value['message'] ?? '';
        _addMessage(sender, message);
      }
    });
  }

  @override
  void dispose() {
    _firebaseListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Host Messages")),
      body: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${msg['sender']}: ${msg['message']}",
              style: TextStyle(color: Colors.black),
            ),
          );
        },
      ),
    );
  }
}

