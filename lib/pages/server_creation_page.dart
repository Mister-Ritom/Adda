import 'dart:typed_data';
import 'package:adda/models/server_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ServerCreationPage extends StatefulWidget {
  const ServerCreationPage({Key? key}) : super(key: key);

  @override
  State<ServerCreationPage> createState() => _ServerCreationPageState();
}

class _ServerCreationPageState extends State<ServerCreationPage> {
  Uint8List? imageFile;
  String _name="",_desc="";

  final PageController _pageController = PageController(initialPage: 0);

  void _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        imageFile = bytes;
      });
    }
  }

  void _goToNextPage() {
    if (_name.isEmpty || _desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all the fields")),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  bool isPng(Uint8List data) {
    const List<int> pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A,
      0x0A];
    return data.length >= pngSignature.length &&
        List<int>.generate(pngSignature.length, (index) => data[index])
            == pngSignature;
  }

  Future<String> uploadToServer()async {
    if(imageFile==null)return "";
    final currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    final storage = FirebaseStorage.instance;
    String contentType = 'image/jpeg'; // Default to JPEG
    if (isPng(imageFile!)) {
      contentType = 'image/png';
    }

    final metadata = SettableMetadata(contentType: contentType);
    final ref = storage.ref().child("serverImages").child("brandImages")
        .child(currentTime);
    //Show scaffold for telling the user that we are uploading the file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading image..."),),
    );
    final uploadTask = await ref.putData(imageFile!,metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  void createServer()async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || imageFile==null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("share a image for your Ghor")),
      );
      return;
    }
    final downloadUrl = await uploadToServer();
    final serverId = UniqueKey().toString();
    // Create the server in the database
    final server = ServerModel(name: _name, description: _desc,
        image: downloadUrl, id: serverId, ownerId: currentUser.uid,
        members: [currentUser.uid]);
    await FirebaseFirestore.instance.collection("servers").doc(serverId)
        .set(server.toJson());
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Ghor"),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable page swiping
        children: [
          _buildPage1(),
          _buildPage2(),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      children: [
        const Center(
          child: Text(
            "This is the first step to creating your biggest audience",
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16,),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width:MediaQuery.of(context).size.width*0.8,
              height: 48,
              child: TextField(
                onChanged: (value) {
                  _name = value;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'House Name',
                  hintText: 'Enter the house name',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16,),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width:MediaQuery.of(context).size.width*0.8,
              height: 48,
              child: TextField(
                onChanged: (value) {
                  _desc = value;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'House Description',
                  hintText: 'Let friends know about your Ghor',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16,),
        ElevatedButton(
          onPressed: _goToNextPage,
          child: const Text("Next"),
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFile != null)
          Center(child: Column(
            children: [
              CircleAvatar(radius:64,foregroundImage: MemoryImage(imageFile!)),
              const SizedBox(height: 8,),
              const Card(child: SizedBox(width: 120,height:48,
                  child: Center(child: Text("Brand Image"))),),
            ],
          )),
        Align(
          alignment: Alignment.bottomRight,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Pick brand Image"),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                width: MediaQuery.of(context).size.width*0.6,
                height: 64,
                child: ElevatedButton(
                  onPressed: createServer,
                  child: const Text("Finish"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
