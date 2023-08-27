import 'package:flutter/material.dart';

class NotificationBody extends StatefulWidget {
  const NotificationBody({super.key});

  @override
  State<NotificationBody> createState() => _NotificationBodyState();
}

class _NotificationBodyState extends State<NotificationBody> {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('Welcome to Adda!'),
        Text('You can add content here Notif'),
      ],
    );
  }
}