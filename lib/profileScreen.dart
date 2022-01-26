import 'package:chatnet/loginScreen.dart';
import 'package:chatnet/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/user.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  UserDetails? user;
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

  @override
  void initState() {
    getUser();
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDetails?>(
      future: getUser(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.grey.shade300,
            body: SafeArea(
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
                                            color: Colors.blueAccent, width: 2),
                                      ),
                                      //NetworkImage
                                      image: DecorationImage(
                                          image: /*AssetImage('images/person.png'),*/ NetworkImage(
                                              snapshot.data!.imageUrl!),
                                          fit: BoxFit.fill)),
                                  margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.0),
                            Container(
                              height: MediaQuery.of(context).size.height / 1.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Column(
                                children: <Widget>[
                                  ListTile(
                                    title: Text("Nom"),
                                    subtitle: Text(snapshot.data!.prenom! +
                                        " " +
                                        snapshot.data!.nom!),
                                    leading: Icon(Icons.person_outline),
                                  ),
                                  ListTile(
                                    title: Text("Grade"),
                                    subtitle: Text(snapshot.data!.grade!),
                                    leading: Icon(Icons.grade_outlined),
                                  ),
                                  ListTile(
                                    title: Text("E-mail"),
                                    subtitle: Text(snapshot.data!.email!),
                                    leading: Icon(Icons.email),
                                  ),
                                  ListTile(
                                    title: Text("Téléphone"),
                                    subtitle: Text(snapshot.data!.tel!),
                                    leading: Icon(Icons.phone),
                                  ),
                                  ListBody(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: ElevatedButton(
                                            onPressed: () async {
                                              SharedPreferences prefs =
                                                  await SharedPreferences
                                                      .getInstance();
                                              final Authentification auth =
                                                  Provider.of<Authentification>(
                                                      context,
                                                      listen: false);
                                              String? id = snapshot.data!.email!
                                                  .trim()
                                                  .substring(
                                                      0,
                                                      snapshot.data!.email!
                                                          .trim()
                                                          .indexOf("@"))
                                                  .toString();
                                              await FirebaseFirestore.instance
                                                  .collection("Users")
                                                  .doc(id)
                                                  .set({"status": false},
                                                      SetOptions(merge: true));
                                              prefs.clear();
                                              auth.clear();
                                              user = null;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoginScreen()),
                                              );
                                            },
                                            child: Text("Se Déconnecter")),
                                      )
                                    ],
                                  ),
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
      },
    );
  }
}
