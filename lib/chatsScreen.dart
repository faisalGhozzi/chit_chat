import 'package:chatnet/model/message.dart';
import 'package:chatnet/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatScreen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Future<UserDetails> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var status = prefs.getBool('isAuthentificated') ?? false;

    if (status) {
      UserDetails u = UserDetails(
          identifiant: prefs.getString("identifiant"),
          nom: prefs.getString("nom"),
          prenom: prefs.getString("prenom"),
          email: prefs.getString("email"),
          tel: prefs.getString("tel"),
          grade: prefs.getString("grade"),
          imageUrl: prefs.getString("imageUrl"),
          status: true);

      return u;
    }
    return UserDetails();
  }

  CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('Users');

  CollectionReference _messagesRef =
      FirebaseFirestore.instance.collection('chatrooms');

  CollectionReference _roomsRef =
      FirebaseFirestore.instance.collection('rooms');

  Future<void> getUsers() async {
    QuerySnapshot querySnapshot = await _usersRef.get();
    users = querySnapshot.docs
        .map((doc) => UserDetails.fromDocuments(doc))
        .toList();

    return;
  }

  Future<bool> getUserInCall(String user) async {
    String id = chatRoomId(user, authUser.prenom!);
    DocumentSnapshot<Object?> querySnapshot = await _roomsRef.doc(id).get();
    return querySnapshot.exists;
  }

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  Map<String, List<Message>> _messagesPerUser = new Map();

  Map<String, List<Message>> get messagesPerUser => _messagesPerUser;

  set messagesPerUser(Map<String, List<Message>> messagesPerUser) {
    _messagesPerUser = messagesPerUser;
  }

  Future<void> getMessages() async {
    UserDetails authUser = await getUser();

    for (var item in users) {
      if (authUser.prenom != item!.prenom!) {
        QuerySnapshot<Object?> querySnapshot = await _messagesRef
            .doc(chatRoomId(authUser.prenom!, item.prenom!))
            .collection("chats")
            .orderBy("time", descending: true)
            .get();
        messages.addAll(
            querySnapshot.docs.map((e) => Message.fromDocument(e)).toList());
        if (authUser.prenom != item.prenom!)
          messagesPerUser[item.prenom!] =
              querySnapshot.docs.map((e) => Message.fromDocument(e)).toList();
      }
    }

    return;
  }

  List<Friend> friends = [];
  late List<UserDetails?> users = [];
  late List<Message> messages = [];
  late List<Container> messagesContainer = [];
  late UserDetails authUser = UserDetails();

  String formatTimestamp(Timestamp timestamp) {
    var format = new DateFormat('hh:mm');
    return format.format(timestamp.toDate());
  }

  void init() async {
    await getUsers();
    await getMessages();
    authUser = await getUser();
    users.forEach((element) {
      messagesPerUser.forEach((key, value) {
        if (value.length > 0 && key == element!.prenom) {
          friends.add(Friend(
              key,
              element.imageUrl!,
              value[0].message!,
              formatTimestamp(value[0].createdAt!),
              element.identifiant!,
              element.nom!,
              element.prenom!,
              element.email!,
              element.grade!,
              element.imageUrl!,
              element.pole!,
              element.status!,
              element.tel!));

          messagesContainer.add(createTile(Friend(
              key,
              element.imageUrl!,
              value[0].message!,
              formatTimestamp(value[0].createdAt!),
              element.identifiant!,
              element.nom!,
              element.prenom!,
              element.email!,
              element.grade!,
              element.imageUrl!,
              element.pole!,
              element.status!,
              element.tel!)));
        }
      });
    });
    setState(() {});

    //friends.add(Friend(name, image, message, msgTime))

    //print(messagesPerUser);
    //messages = await getMessages();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  Container createTile(Friend friend) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF565973), width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 6.0, 16.0, 6.0),
              child: Container(
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                      image: NetworkImage(friend.image), fit: BoxFit.cover),
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      String? id = authUser.email!
                          .trim()
                          .substring(0, authUser.email!.trim().indexOf("@"))
                          .toString();
                      String roomId =
                          chatRoomId(authUser.prenom!, friend.prenom);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Chat(
                                  authUser: authUser,
                                  chatroomId: roomId,
                                  user: UserDetails(
                                      identifiant: friend.identifiant,
                                      email: friend.email,
                                      grade: friend.grade,
                                      imageUrl: friend.imageUrl,
                                      nom: friend.nom,
                                      prenom: friend.prenom,
                                      pole: friend.pole,
                                      status: friend.status,
                                      tel: friend.tel),
                                )),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          friend.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                        SizedBox(width: 6.0),
                        Text(
                          friend.msgTime,
                          style: TextStyle(
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    friend.message,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> createTopTile() {
    List<OnlinePersonAction> l = [];
    for (var item in users) {
      if (item!.prenom != authUser.prenom) {
        if (item.status == true) {
          l.add(OnlinePersonAction(
            personImagePath: item.imageUrl,
            actColor: Colors.greenAccent,
          ));
        }
        if (item.status == false) {
          l.add(OnlinePersonAction(
            personImagePath: item.imageUrl,
            actColor: Colors.redAccent,
          ));
        }
        /*  var t = FutureBuilder<bool>(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data == true) {
                l.add(OnlinePersonAction(
                  personImagePath: item.imageUrl,
                  actColor: Colors.orangeAccent,
                ));
              }
            }
            return Container();
          },
          future: getUserInCall(item.prenom!),
        );
        if (item.status == true && t.future == true) {
          l.add(OnlinePersonAction(
            personImagePath: item.imageUrl,
            actColor: Colors.orangeAccent,
          ));
        }*/
      }
    }
    return l.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final liste = SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: messagesContainer.reversed.toList(),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 20.0),
              child: Text(
                'Chats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(5.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0.0, 1.5),
                      blurRadius: 1.0,
                      spreadRadius: -1.0,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(children: createTopTile()),
                  ),
                ),
              ),
            ),
            Flexible(
              child: liste,
            ),
          ],
        ),
      ),
    );
  }
}

class OnlinePersonAction extends StatelessWidget {
  final String? personImagePath;
  final Color? actColor;
  const OnlinePersonAction({
    Key? key,
    this.personImagePath,
    this.actColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            padding: const EdgeInsets.all(3.4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(
                width: 2.0,
                color: const Color(0xFF558AED),
              ),
            ),
            child: Container(
              width: 54.0,
              height: 54.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                image: DecorationImage(
                    image: NetworkImage(personImagePath!), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10.0,
          right: 10.0,
          child: Container(
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: actColor,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                width: 1.0,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Friend {
  //   final String? identifiant;
  // final String? nom;
  // final String? prenom;
  // final String? email;
  // final String? tel;
  // final String? grade;
  // final String? pole;
  // final String? imageUrl;
  // final bool? status;
  String identifiant, nom, prenom, email, tel, grade, pole, imageUrl;
  bool status;
  String name, image, message, msgTime;

  Friend(
      this.name,
      this.image,
      this.message,
      this.msgTime,
      this.identifiant,
      this.nom,
      this.prenom,
      this.email,
      this.grade,
      this.imageUrl,
      this.pole,
      this.status,
      this.tel);
}

/* List<UserDetails> l = await FirebaseApi().getUsers(); */
