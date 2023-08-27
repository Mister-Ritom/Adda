import 'package:adda/models/server_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';

class ChatBody extends StatefulWidget {
  final ServerModel server;
  final Map<String,dynamic> channelRef;
  const ChatBody({super.key, required this.server, required this.channelRef});

  @override
  State<ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<ChatBody> {

  final TextEditingController _textEditingController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _getHintText() {
    final String hintText = widget.channelRef['name'];
    if (hintText.length > 15) {
      return '${hintText.substring(0, 15)}...';
    } else {
      return hintText;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages() {
    final messageCollection = FirebaseFirestore.instance.collection("serverData")
        .doc(widget.server.id).collection("channels").doc(widget.channelRef['name']).collection("messages");
    return messageCollection.orderBy('timestamp', descending: true).snapshots();
  }

  void _sendMessage() async {
    final message0 = _textEditingController.text.trim();
    if (message0.isNotEmpty&&currentUser!=null) {
      _textEditingController.clear();
      //create a vibration
      HapticFeedback.vibrate();
      final Map<String, dynamic> message = {
        'message': message0,
        'sender': currentUser!.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      //check if the messages exists and add. if it doesn't exist then create it
      if (widget.channelRef['messages'] == null) {
        widget.channelRef['messages'] = [];
      }
      widget.channelRef['messages'].add(message);
      await FirebaseFirestore.instance
          .collection('serverData')
          .doc(widget.server.id)
          .collection('channels')
          .doc(widget.channelRef['name']).collection("messages").add(message);
    }
  }

  String getTimeString(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    //check if its been more than one. it its less than one day return only time with pm or am. if its more than one day return date and time with pm or am
    if (date.difference(DateTime.now()).inDays == 0) {
      return '${date.hour}:${date.minute} ${date.hour > 12 ? 'p.m.' : 'a.m.'}';
    } else {
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute} ${date.hour > 12 ? 'pm' : 'am'}';
    }
  }

  Future<UserModel> getUser(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return UserModel.fromJson(userDoc.data()!);
  }

  Future<Widget> buildMessage(Map<String, dynamic> message) async {
    final user = await getUser(message['sender']);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfilePicture(
                radius: 18,
                name: user.name,
                img: user.photoUrl,
                fontsize: 12,
              ),
              const SizedBox(width: 8.0),
              Text(
                user.name,
                style: GoogleFonts.robotoMono(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                )
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3.0),
                child: Text(
                  getTimeString(message['timestamp']),
                  style: const TextStyle(
                      color: Colors.grey,fontSize: 10,
                      fontWeight: FontWeight.w300
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 2, 8, 0),
            child: Text(message['message']),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 45),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: getMessages(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data();
                    return FutureBuilder<Widget>(
                      future: buildMessage(message),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return snapshot.data!;
                        } else {
                          return const Spacer();
                        }
                      },
                    );
                  },
                );
              } else {
                return const Spacer();
              }
            },
          ),
        ),
        SizedBox(
          height: 45,
          child: AppBar(
            toolbarHeight: 45,
            elevation: 8,
            title: Text("# ${widget.channelRef['name']}"),
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextField(
                textAlign: TextAlign.start,
                minLines: 1,
                maxLines: 5,
                controller: _textEditingController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  border: InputBorder.none,
                  hintText: 'Message #${_getHintText()}',
                  prefixIcon: const Icon(FontAwesomeIcons.faceSmile),
                  //change hint color to light grey
                  hintStyle: TextStyle(color: Colors.grey.shade800),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ),
              ),
            )
        ),
      ],
    );
  }
}