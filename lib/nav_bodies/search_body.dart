import 'package:adda/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class SearchBody extends StatefulWidget {
  const SearchBody({super.key});

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {

  String _searchTerm = "";

  Stream<QuerySnapshot<Map<String, dynamic>>> getSearchStream() {
    if (_searchTerm.characters.length>1) {
      return FirebaseFirestore.instance.collection("users")
        .orderBy("username")
          .startAt([_searchTerm])
            .endAt(["$_searchTerm\uf8ff"])
              .limit(25)
              .snapshots();
    }
    return FirebaseFirestore.instance.collection("users")
        .orderBy("username")
        .limit(10)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)
                )
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
        ),
        //StreamBuilder with search stream
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getSearchStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Something went wrong");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasData) {
              if (snapshot.data!=null&&snapshot.data!.docs.isNotEmpty) {
                List<UserModel> users = snapshot.data!.docs.map((e) => UserModel.fromJson(e.data())).toList();
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: ProfilePicture(
                          name: users[index].name,
                          radius: 21, fontsize: 16,
                          img: users[index].photoUrl,
                        ),
                        subtitle: Text(users[index].name),
                        title: Text(users[index].username),
                      );
                    },
                  ),
                );
              }
            }
            return const Text("No user found");
          },
        )
      ],
    );
  }
}