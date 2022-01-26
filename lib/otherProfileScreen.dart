import 'package:chatnet/model/user.dart';
import 'package:chatnet/repertoireScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatScreen.dart';

class OtherProfile extends StatefulWidget {
  final String? identifiant;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? tel;
  final String? grade;
  final String? pole;
  final String? imageUrl;
  final bool? status;

  OtherProfile(
      {Key? key,
      this.identifiant,
      this.nom,
      this.prenom,
      this.email,
      this.tel,
      this.grade,
      this.pole,
      this.imageUrl,
      this.status})
      : super(key: key);

  @override
  _OtherProfileState createState() => _OtherProfileState();
}

class _OtherProfileState extends State<OtherProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? roomId;

  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
  }

  Future<UserDetails?> getUser() async {
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
          pole: prefs.getString("pole"),
          imageUrl: prefs.getString("imageUrl"),
          status: true);

      return u;
    }
  }

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${this.widget.prenom} ${this.widget.nom}"),
        ),
        backgroundColor: Colors.grey.shade300,
        body: FutureBuilder<UserDetails?>(
            future: getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ),
                );
              }
              if (snapshot.hasData) {
                return SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue.shade200, Colors.blue])),
                    child: SingleChildScrollView(
                      child: Stack(
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.fromLTRB(16.0, 45.0, 16.0, 25.0),
                            child: Column(
                              children: <Widget>[
                                Stack(
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      height: 100,
                                      width: 100,
                                      decoration: ShapeDecoration(
                                          shape: CircleBorder(
                                            side: BorderSide(
                                                color: Colors.blueAccent,
                                                width: 2),
                                          ),
                                          //NetworkImage
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                  this.widget.imageUrl!),
                                              fit: BoxFit.fill)),
                                      margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.0),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 1.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      ListTile(
                                        title: Text("Nom"),
                                        subtitle: Text(
                                            "${this.widget.prenom} ${this.widget.nom}"),
                                        leading: Icon(Icons.person_outline),
                                      ),
                                      ListTile(
                                        title: Text("Grade"),
                                        subtitle: Text(this.widget.grade!),
                                        leading: Icon(Icons.grade_outlined),
                                      ),
                                      ListTile(
                                        title: Text("E-mail"),
                                        subtitle: Text(this.widget.email!),
                                        leading: Icon(Icons.email),
                                      ),
                                      ListTile(
                                        title: Text("Téléphone"),
                                        subtitle: Text(this.widget.tel!),
                                        leading: Icon(Icons.phone),
                                      ),
                                      ListBody(
                                        children: [
                                          FutureBuilder<UserDetails?>(
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                if (snapshot.data!.pole ==
                                                    "Administrateurs") {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            1.2,
                                                        child: ElevatedButton(
                                                          child:
                                                              Text("Contacter"),
                                                          onPressed: () {
                                                            String? id = widget
                                                                .email!
                                                                .trim()
                                                                .substring(
                                                                    0,
                                                                    widget
                                                                        .email!
                                                                        .trim()
                                                                        .indexOf(
                                                                            "@"))
                                                                .toString();
                                                            String roomId =
                                                                chatRoomId(
                                                                    snapshot
                                                                        .data!
                                                                        .prenom!,
                                                                    widget
                                                                        .prenom!);
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          Chat(
                                                                            authUser:
                                                                                snapshot.data,
                                                                            chatroomId:
                                                                                roomId,
                                                                            user: UserDetails(
                                                                                identifiant: widget.identifiant,
                                                                                email: widget.email,
                                                                                grade: widget.grade,
                                                                                imageUrl: widget.imageUrl,
                                                                                nom: widget.nom,
                                                                                prenom: widget.prenom,
                                                                                pole: widget.pole,
                                                                                status: widget.status,
                                                                                tel: widget.tel),
                                                                          )),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            1.2,
                                                        child: ElevatedButton(
                                                            onPressed: () {
                                                              showDialog<void>(
                                                                context:
                                                                    context,
                                                                barrierDismissible:
                                                                    false, // user must tap button!
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return AlertDialog(
                                                                    title: const Text(
                                                                        'Supression'),
                                                                    content:
                                                                        SingleChildScrollView(
                                                                      child:
                                                                          ListBody(
                                                                        children: const <
                                                                            Widget>[
                                                                          Text(
                                                                              "Voudriez-vous vraiment supprimer l'utilisateur?"),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    actions: <
                                                                        Widget>[
                                                                      TextButton(
                                                                        child: const Text(
                                                                            'Oui'),
                                                                        onPressed:
                                                                            () async {
                                                                          String? id = widget
                                                                              .email!
                                                                              .trim()
                                                                              .substring(0, widget.email!.trim().indexOf("@"))
                                                                              .toString();
                                                                          await _firestore
                                                                              .collection('Users')
                                                                              .doc(id)
                                                                              .delete();
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                          Navigator
                                                                              .push(
                                                                            context,
                                                                            MaterialPageRoute(builder: (context) => Repertoire()),
                                                                          );
                                                                        },
                                                                      ),
                                                                      TextButton(
                                                                        child: const Text(
                                                                            'Non'),
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        },
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            child: Text(
                                                                "Supprimer l'utilisateur")),
                                                      ),
                                                      widget.pole !=
                                                              "Administrateurs"
                                                          ? SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  1.2,
                                                              child:
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        showDialog<
                                                                            void>(
                                                                          context:
                                                                              context,
                                                                          barrierDismissible:
                                                                              false, // user must tap button!
                                                                          builder:
                                                                              (BuildContext context) {
                                                                            return AlertDialog(
                                                                              title: const Text('Adminstrateur'),
                                                                              content: SingleChildScrollView(
                                                                                child: ListBody(
                                                                                  children: const <Widget>[
                                                                                    Text('Voudriez-vous vraiment Désigner cette utilisateur adminstrateur ?'),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              actions: <Widget>[
                                                                                TextButton(
                                                                                  child: const Text('Oui'),
                                                                                  onPressed: () async {
                                                                                    String? id = widget.email!.trim().substring(0, widget.email!.trim().indexOf("@")).toString();
                                                                                    await _firestore.collection('Users').doc(id).set({
                                                                                      "pole": "Administrateurs"
                                                                                    }, SetOptions(merge: true));
                                                                                    Navigator.of(context).pop();
                                                                                    Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(builder: (context) => Repertoire()),
                                                                                    );
                                                                                  },
                                                                                ),
                                                                                TextButton(
                                                                                  child: const Text('Non'),
                                                                                  onPressed: () {
                                                                                    Navigator.of(context).pop();
                                                                                  },
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                          "Désigner administrateur")),
                                                            )
                                                          : Container()
                                                    ],
                                                  );
                                                } else {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width /
                                                            1.2,
                                                        child: ElevatedButton(
                                                          child:
                                                              Text("Contacter"),
                                                          onPressed: () {
                                                            String? id = widget
                                                                .email!
                                                                .trim()
                                                                .substring(
                                                                    0,
                                                                    widget
                                                                        .email!
                                                                        .trim()
                                                                        .indexOf(
                                                                            "@"))
                                                                .toString();
                                                            String roomId =
                                                                chatRoomId(
                                                                    snapshot
                                                                        .data!
                                                                        .prenom!,
                                                                    widget
                                                                        .prenom!);
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          Chat(
                                                                            authUser:
                                                                                snapshot.data,
                                                                            chatroomId:
                                                                                roomId,
                                                                            user: UserDetails(
                                                                                identifiant: widget.identifiant,
                                                                                email: widget.email,
                                                                                grade: widget.grade,
                                                                                imageUrl: widget.imageUrl,
                                                                                nom: widget.nom,
                                                                                prenom: widget.prenom,
                                                                                pole: widget.pole,
                                                                                status: widget.status,
                                                                                tel: widget.tel),
                                                                          )),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    snapshot.error.toString());
                                              } else {
                                                return Container(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1,
                                                  ),
                                                );
                                              }
                                            },
                                            future: getUser(),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else {
                return Container(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ),
                );
              }
            }));
  }
}
