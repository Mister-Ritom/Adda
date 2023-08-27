import 'package:adda/nav_bodies/chat_body.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/server_model.dart';
import '../models/user_model.dart';
import '../pages/server_creation_page.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  int _currentServer = 1;
  int _currentChannel = 0;
  String _joinId = "";
  final pageController = PageController();
  List<ServerModel> _servers = [];
  List<Map<String,dynamic>> channels = [];

  Future<UserModel> getServerOwner(String ownerId) async {
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .get();

    return UserModel.fromJson(snapshot.data() as Map<String,dynamic>);
  }
  
  Future<List<DocumentSnapshot>> getServersWithCurrentUserMember(String currentUserID) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('servers')
        .where('members', arrayContains: currentUserID)
        .get();

    return snapshot.docs;
  }

  Future<List<ServerModel>> getJoinedServers() async {
    List<ServerModel> servers = [];
    servers.add(ServerModel(
      id: 'add_server',
      name: "Add Ghor",
      ownerId: '', description: '', image: '',
    ));

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser!=null) {
      // Get servers and add them to list
      final serversList = await getServersWithCurrentUserMember(currentUser.uid);
      for (final server in serversList) {
        final serverData = server.data() as Map<String,dynamic>;
        servers.add(ServerModel.fromJson(serverData));
      }
    }

    return servers;
  }

  String _searchText = "";

  Future<List<Map<String,dynamic>>> getServerChannels(server) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser!=null) {
      try {
        final channelCollection= FirebaseFirestore.instance.collection("serverData")
            .doc(server.id).collection("channels");
        //check if searching and add a query with start and end
        if (_searchText.isNotEmpty) {
          final channelList = await channelCollection.startAt([_searchText])
              .endAt(["$_searchText\uf8ff"]).orderBy("name").get();
          return channelList.docs.map((e) => e.data()).toList();
        }
        final channelList = await channelCollection.get();
        return channelList.docs.map((e) => e.data()).toList();
      }
      catch(_) {
        return [];
      }
    }
    return [];
  }
  
  String getTimestamp(int creationTime) {
    final time = DateTime.fromMillisecondsSinceEpoch(creationTime);
    return "${time.day}/${time.month}/${time.year}";
  }

  void joinServer(BuildContext dialogContext) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser==null) {
      //If the user is not logged in, show an error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You need to be logged in to join a server"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    //Join a server with the given id
    FirebaseFirestore.instance.collection('servers').doc(_joinId).get().then((value) {
      if(value.exists) {
        final serverData = value.data() as Map<String,dynamic>;
        final membersList = serverData['members'] as List<dynamic>;
        if (membersList.contains(currentUser.uid)) {
          //If the user is already a member of the server, show an error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You are already a member of this server"),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(dialogContext);
        }
        membersList.add(currentUser.uid);
        FirebaseFirestore.instance.collection('servers').doc(_joinId).update({
          'members': membersList,
        }).then((_) {
          //If the server is joined successfully, show a success message
          setState(() {
            _servers.add(ServerModel.fromJson(serverData));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You have joined the server successfully"),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(dialogContext);
        });
      }
      else {
        //If the server doesn't exist, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("The server you are trying to join doesn't exist"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void openJoinServerDialog() {
    //Show a dialog for joining a server with a texel for server id
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.home_outlined,size: 32,),
                    title: Text("Join Ghor",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    subtitle: Text(
                      "Join your friends Ghor",
                      style:Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    _joinId = value;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'House ID',
                    hintText: 'Enter the house id or invite link',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      joinServer(context);
                    },
                    child: const Text('Join'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openCreateServerDialog() {
    //Navigate to server creation page
    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
    const ServerCreationPage()));
  }

  void openAddServerDialog() {
    //Create a custom dialog for adding servers
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text("Add Ghor",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    subtitle: Text(
                        "Join or create a server to start chatting with your friends",
                        style:Theme.of(context).textTheme.bodySmall,
                    ),

                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Join Server'),
                    subtitle: const Text("Join your friends Ghor"),
                    onTap: () {
                      Navigator.pop(context);
                      openJoinServerDialog();
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.create),
                    title: const Text('Create Server'),
                    subtitle: const Text("Create a new server and invite your friends"),
                    onTap: () {
                      Navigator.pop(context);
                      openCreateServerDialog();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openCreateChannelDialog() {
    String channelName = "";
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.home_outlined,size: 32,),
                    title: Text("Create Channel",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    subtitle: Text(
                      "Create a new channel in ${_servers[_currentServer].name}",
                      style:Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    channelName = value;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Channel Name',
                    hintText: 'Enter the channel name',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      //check if channel already exists and show the error to user
                      //TODO needs to rewriting
                      for (final channel in channels) {
                        if (channel['name'].toLowerCase()==channelName.toLowerCase()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Channel already exists"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                      }
                      Navigator.pop(context);
                      //Create channel in firestore
                      final server = _servers[_currentServer];
                      final channelCollection = FirebaseFirestore.instance.collection("serverData")
                          .doc(server.id).collection("channels");
                      final data = {
                        'name': channelName,
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                      };
                      channelCollection.doc(channelName).set(data);
                      setState(() {
                        channels.add(data);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Channel created successfully"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  

  void openBottomDialog() {
    //Open a modal bottom dialog for showing user their options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            buildServerInfo(),
            //show create channel only if the current user is the owner
            if (_servers[_currentServer].ownerId==FirebaseAuth.instance.currentUser!.uid)
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create Channel'),
                subtitle: const Text("Create a new channel in this server"),
                onTap: () {
                  Navigator.pop(context);
                  openCreateChannelDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Invite Friends'),
              subtitle: const Text("Invite your friends to this server"),
              onTap: () {
                Navigator.pop(context);
                //copy the server id to clipboard
                final server = _servers[_currentServer];
                Clipboard.setData(ClipboardData(text: server.id));
                //show another dialog for the invite link
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      insetPadding: const EdgeInsets.all(16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: const Icon(Icons.home_outlined,size: 32,),
                                title: Text("Invite Friends",
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                subtitle: Text(
                                  "Invite your friends to ${server.name}",
                                  style:Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                            //Selectable text with a icon button
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                        vertical: 16.0
                                      ),
                                      child: SelectableText(
                                        "Invite link ${server.id}",
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: server.id));
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Invite link copied to clipboard"),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Invite link copied to clipboard"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Leave Server'),
              subtitle: const Text("Leave this server"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You have left the server"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildServerInfo() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_servers[_currentServer].image),
              ),
              title: Text(_servers[_currentServer].name),
              subtitle: Text(_servers[_currentServer].description),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    const Icon(FontAwesomeIcons.hashtag,size: 12,),
                    const SizedBox(width: 8,),
                    Text("${channels.length} Channels",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]
                ),
                //A row for showing members count
                Row(
                  children : [
                    const Icon(FontAwesomeIcons.userGroup,size: 12,),
                    const SizedBox(width: 8,),
                    Text("${_servers[_currentServer].members.length} Members",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]
                ),
              ],
            ),
            //show a created by and created on
            SizedBox(
              width: MediaQuery.of(context).size.width*0.8,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: FutureBuilder<UserModel>(
                  future: getServerOwner(_servers[_currentServer].ownerId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final owner = snapshot.data!;
                      return ListTile(
                        trailing: ProfilePicture(
                          img: owner.photoUrl,
                          radius: 14, name: owner.name, fontsize: 10,
                        ),
                        title: Text("Created by ${owner.name}",
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text("On ${getTimestamp(_servers[_currentServer].creationTime)}",
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 10,);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildServerWidget(ServerModel server,int index) {
    bool isSelected = _currentServer == index;
    return SizedBox(
      height: 60,
      child: Column(
        children: [
          Center(
            child: FittedBox(
              child: Material(
                //Circle shape with red border
                shape: isSelected? CircleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ),
                ):const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentServer = index;
                    });
                  },
                  child: CircleAvatar(
                    radius: 21,
                    backgroundImage: NetworkImage(server.image),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              server.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 8,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Column buildFirstPage(ServerModel currentServer, List<Widget> cards, BuildContext context) {
    return Column(
      children: [
        //Appbar for showing current server name and image
        AppBar(
          title: Text(currentServer.name),
          leading: Padding(
            padding: const EdgeInsets.all(4.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(currentServer.image),
            ),
          ),
          toolbarHeight: 45,
          elevation: 8,
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: cards.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context,index) {
                return cards[index];
              }
          ),
        ),
        Text("Channels",style: Theme.of(context).textTheme.headlineMedium,),
        Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width*0.8,
              height: 42,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Search Channels',
                  hintText: 'Enter the channel name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child:ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: channels.length,
                  //add a divider
                  itemBuilder: (context,index) {
                    final channel = channels[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4,horizontal: 16),
                      onTap: () {
                        setState(() {
                          _currentChannel = index;
                        });
                        pageController.animateToPage(1, duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
                      },
                      leading: const Icon(FontAwesomeIcons.hashtag,size: 16,),
                      title: Text(channel['name']),
                    );
                  }, separatorBuilder: (BuildContext context, int index) { return const Divider(); },
                ),
        ),
      ],
    );
  }

  Align buildServerSelector(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: // A scrollable horizontal list
      Container(
        decoration: BoxDecoration(
          //Top left and right border radius to 20
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).cardColor,
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        child:ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _servers.length,
          itemBuilder: (context,index) {
            if(index==0) {
              return Column(
                children: [
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: openAddServerDialog,
                      icon: Icon(FontAwesomeIcons.plus,
                        color: Theme.of(context).colorScheme.primary,size: 22,),
                    ),
                  ),
                  const SizedBox(
                    height:2,
                  ),
                  SizedBox(
                    height: 10,
                    width: 50,
                    child: FittedBox(
                      child: Text("Add Ghor",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                ],
              );
            }
            return buildServerWidget(_servers[index],index);
          },
        ),
      ),
    );
  }

  List<Widget> getCards() {
    final currentServer = _servers[_currentServer];
    List<Widget> cards = [];
    final firstCard = Card(
        child: SizedBox(
          height: 100,
          width: MediaQuery.of(context).size.width*0.8,
          child: Center(
            child: ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(currentServer.name),
              subtitle: Text(currentServer.description),
              trailing: IconButton(onPressed: openBottomDialog,  icon:const Icon(Icons.more_vert)),
            ),
          ),
        )
    );
    cards.add(firstCard);
    final secondCard = Card(
        child: SizedBox(
          height: 100,
          width: MediaQuery.of(context).size.width*0.8,
          child: Center(
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.userGroup),
              title: Text("${currentServer.members.length} members"),
              subtitle: Text(
                  "${currentServer.name} has ${currentServer.members.length} members including you"
              ),
            ),
          ),
        )
    );
    cards.add(secondCard);
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    if (_servers.length<2) {
      return buildServerSelector(context);
    }
    final currentServer = _servers[_currentServer];
    final cards = getCards();
    return PageView(
      controller: pageController,
      children: [
        Stack(
          children: [
            buildFirstPage(currentServer, cards, context),
            buildServerSelector(context),
          ],
        ),
        //Check if channels is empty and show a button to create channels
        if (channels.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FontAwesomeIcons.hashtag,size: 64,),
                const SizedBox(height: 16,),
                const Text("No channels found"),
                const SizedBox(height: 16,),
                ElevatedButton(
                  onPressed: openCreateChannelDialog,
                  child: const Text("Create Channel"),
                ),
              ],
            ),
          )
        else ChatBody(server: _servers[_currentServer], channelRef: channels[_currentChannel],)
      ],
    );
  }

  void onState()async {
    final newServers = await getJoinedServers();
    if (newServers.length>1) {
      final newChannels = await getServerChannels(newServers[_currentServer]);
      setState(() {
        _servers = newServers;
        channels = newChannels;
      });
    }
    else {
      setState(() {
        _servers = newServers;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    onState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

}