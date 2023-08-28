import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/achievement_model.dart';
import '../models/user_model.dart';
import '../pages/settings_page.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  Future<UserModel> getCurrentUser() {
    final userId = FirebaseAuth.instance.currentUser!.uid; //Cant be null
    return UserModel.getUser(userId);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserCache() {
    final userId = FirebaseAuth.instance.currentUser!.uid; //Cant be null
    final firestore = FirebaseFirestore.instance;
    return firestore.collection("userCache").doc(userId).get();
  }

  List<Achievement> toAchievements(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final achievements = <Achievement>[];
    final data = snapshot.data()!;
    data['achievements'].forEach((achievement) {
      achievements.add(Achievement.fromJson(achievement));
    });
    return achievements;
  }

  String descWithInfo(String s, DocumentSnapshot<Map<String, dynamic>> snapshot,
      UserModel user) {
    final data = snapshot.data()!;
    final views = data["views"] as int;
    final messageCount = data["messageCount"] as int;

    final dateTime = DateTime.fromMillisecondsSinceEpoch(user.createdAt)
        .toLocal()
        .toString();
    final creationDate = dateTime.split(" ")[0];
    final accountCreationTime = dateTime.split(" ")[1];

    return s
        .replaceAll("{views}", "$views")
        .replaceAll("{messageCount}", "$messageCount")
        .replaceAll("{creationDate}", creationDate)
        .replaceAll("creationTime}", accountCreationTime);
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getCurrentUser(),
        builder: (context, snapshot) {
          //If loading show circular progress indicator. if error show error else show column
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          } else {
            final user = snapshot.data as UserModel;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: Text(user.username,
                      style: Theme.of(context).textTheme.headlineMedium),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ProfilePicture(
                        name: user.name,
                        radius: 14,
                        fontsize: 12,
                        img: user.photoUrl),
                  ),
                  elevation: 12,
                  actions: [
                    IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(FontAwesomeIcons.gear))
                  ],
                  toolbarHeight: 50,
                ),
                const SizedBox(height: 20),
                Center(
                    child: ProfilePicture(
                        name: user.name,
                        radius: 64,
                        fontsize: 36,
                        img: user.photoUrl)),
                const SizedBox(height: 20),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Text(user.email,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Achievements",
                          style: Theme.of(context).textTheme.titleLarge),
                    )),
                FutureBuilder(
                  future: getUserCache(),
                  builder: (context, snapshot) {
                    //If loading show circular progress indicator. if error show error else show listview
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text(
                              'Something went wrong ${snapshot.error.toString()}'));
                    } else {
                      final achievements = toAchievements(snapshot.data!);
                      return Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            return buildAchievementCard(
                                context,
                                achievements[index],
                                descWithInfo(achievements[index].description,
                                    snapshot.data!, user));
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }
        });
  }

  Widget buildAchievementCard(
      BuildContext context, Achievement achievement, String desc) {
    return Stack(
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                  //Gradient color
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: achievement.colors,
                  ),
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        Card(
          color: Colors.transparent,
          // RoundedRectangleBorder for circular border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: NetworkImage(achievement.icon),
                      width: 16,
                      height: 16,
                      color: achievement.textColor,
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: Text(
                        achievement.title,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: achievement.textColor,
                                ),
                        overflow: TextOverflow.clip,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                Text(desc,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: achievement.textColor,
                        )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
