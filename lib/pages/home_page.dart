import 'package:adda/nav_bodies/home_body.dart';
import 'package:adda/nav_bodies/notif_body.dart';
import 'package:adda/nav_bodies/search_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../nav_bodies/profile_body.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _currentIndex = 0;
  Widget _currentBody = const HomeBody();

  final bodies = [
    const HomeBody(),
    const SearchBody(),
    const NotificationBody(),
    const ProfileBody(),
  ];

  void _onChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentBody = bodies[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.rocketchat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.searchengin), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.bell), label: 'Notifications'),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.user), label: 'Profile'),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness==Brightness.dark?SystemUiOverlayStyle.light:SystemUiOverlayStyle.dark,
            child: SafeArea(child: _currentBody
            )
      ),
    );
  }
}
