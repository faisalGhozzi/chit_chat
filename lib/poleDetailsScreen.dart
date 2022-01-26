import 'package:chatnet/groupChat.dart';
import 'package:chatnet/otherProfileScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PoleDetails extends StatefulWidget {
  final String? pole;
  PoleDetails(String this.pole);
  static String tag = "PoleDetails";

  @override
  _PoleDetailsState createState() => _PoleDetailsState();
}

class _PoleDetailsState extends State<PoleDetails> {
  String name = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GroupChat(
                            chatroomId: widget.pole,
                          )),
                );
              },
              icon: Icon(Icons.group_outlined)),
        ],
        title: Card(
          child: TextField(
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Recherche...'),
            onChanged: (val) {
              setState(() {
                name = val;
              });
            },
          ),
        ),

        // leading: Container(),
      ),
      body: StreamBuilder(
        stream: (name != "")
            ? FirebaseFirestore.instance
                .collection('Users')
                //.where("pole", isEqualTo: widget.pole)
                .where("prenom", isGreaterThanOrEqualTo: name[0].toUpperCase())
                .where("prenom", isLessThanOrEqualTo: name[0].toLowerCase())
                .snapshots()
            : FirebaseFirestore.instance
                .collection('Users')
                .where("pole", isEqualTo: widget.pole)
                .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
              child: ListView.builder(
                itemCount: snapshot.data?.docs.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OtherProfile(
                                  email: snapshot.data?.docs
                                      .elementAt(index)['email'],
                                  grade: snapshot.data?.docs
                                      .elementAt(index)['grade'],
                                  imageUrl: snapshot.data?.docs
                                      .elementAt(index)['imageUrl'],
                                  nom: snapshot.data?.docs
                                      .elementAt(index)['nom'],
                                  pole: snapshot.data?.docs
                                      .elementAt(index)['pole'],
                                  prenom: snapshot.data?.docs
                                      .elementAt(index)['prenom'],
                                  status: snapshot.data?.docs
                                      .elementAt(index)['status'],
                                  tel: snapshot.data?.docs
                                      .elementAt(index)['tel'],
                                )),
                      );
                    },
                    child: ListTile(
                      trailing: null,
                      leading: Stack(
                        clipBehavior: Clip.antiAlias,
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
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  image: DecorationImage(
                                      image: NetworkImage(snapshot.data?.docs
                                          .elementAt(index)['imageUrl']),
                                      fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 35.0,
                            right: 10.0,
                            child: Container(
                              width: 10.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                color: snapshot.data?.docs
                                        .elementAt(index)['status']
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  width: 0.5,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(snapshot.data?.docs.elementAt(index)['nom'] +
                          " " +
                          snapshot.data?.docs.elementAt(index)['prenom']),
                    ),
                  );
                },
              ),
            );
          } else {
            return Shimmer.fromColors(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return ListTile();
                  },
                  itemCount: 10,
                ),
                baseColor: Colors.grey,
                highlightColor: Colors.teal);
          }
        },
      ),
    );
  }
}
