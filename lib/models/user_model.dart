//User model class with name,email,phone,uid,profile pic,created at,username
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String name;
  String email;
  int? phone;
  String uid;
  String? photoUrl;
  int createdAt;
  String username;

  UserModel({
    required this.username,
    required this.name,
    required this.email,
    this.phone,
    required this.uid,
    this.photoUrl,
    int? createdAt,  // Allow passing a custom createdAt value
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      uid: json['uid'],
      photoUrl: json['photoUrl'],
      createdAt: json['created_at'],
      username: json['username'],
    );
  }

  static Future<UserModel> getUser(String userId)async {
    // Get user document from firestore
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users')
        .doc(userId).get();
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'uid': uid,
      'photoUrl': photoUrl,
      'created_at': createdAt,
      'username': username,
    };
  }
}