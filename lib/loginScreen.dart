import 'package:chatnet/homeScreen.dart';
import 'package:chatnet/main.dart';
import 'package:chatnet/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  static String tag = "login";
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

  final TextEditingController _identifiant = TextEditingController();

  final TextEditingController _password = TextEditingController();

  Future<void> checkLogin() async {
    final Authentification auth =
        Provider.of<Authentification>(context, listen: false);

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var status = prefs.getBool('isAuthentificated') ?? false;

    if (status) {
      UserDetails u = UserDetails(
          identifiant: prefs.getString("identifiant"),
          nom: prefs.getString("nom"),
          prenom: prefs.getString("prenom"),
          email: prefs.getString("email"),
          tel: prefs.getString("tel"),
          pole: prefs.getString("pole"),
          grade: prefs.getString("grade"),
          imageUrl: prefs.getString("imageUrl"),
          status: true);
      auth.user = u;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      prefs.clear();
      auth.clear();
    }
  }

  @override
  void initState() {
    checkLogin();
    setState(() {});
    super.initState();
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  final databaseReference = FirebaseFirestore.instance.collection("users");

  UserDetails? user;

  final user_not_found = SnackBar(
    content: Text('Identifiant incorrecte !'),
    elevation: 100.0,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(bottom: 30, left: 10, right: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
    backgroundColor: Colors.blue.shade300,
  );

  final wrong_pass = SnackBar(
    content: Text('Mot de passe Incorrecte !'),
    elevation: 100.0,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(bottom: 30, left: 10, right: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
    backgroundColor: Colors.blue.shade300,
  );

  final empty_fields = SnackBar(
    content: Text('Veuillez remplir Tous les champs !'),
    elevation: 100.0,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(bottom: 30, left: 10, right: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
    backgroundColor: Colors.blue.shade300,
  );

  final login = SnackBar(
    content: Text('Logged in !'),
    elevation: 100.0,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(bottom: 30, left: 10, right: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
    backgroundColor: Colors.blue.shade300,
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: size.width,
            minHeight: size.height,
          ),
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    "images/Logo.svg",
                    width: 300,
                    height: 300,
                  ),
                ),
              ),
              Center(
                child: Form(
                    child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: field(size, "Email", Icons.account_box_outlined,
                            false, _identifiant),
                      ),
                      SizedBox(
                        height: size.height / 40,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: field(size, "Identifiant",
                            Icons.password_outlined, true, _password),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () async {
                            if (_identifiant.text.isNotEmpty &&
                                _password.text.isNotEmpty) {
                              String? id = _identifiant.text
                                  .trim()
                                  .substring(
                                      0, _identifiant.text.trim().indexOf("@"))
                                  .toString();
                              DocumentSnapshot data = await FirebaseFirestore
                                  .instance
                                  .collection("Users")
                                  .doc(id)
                                  .get();
                              final Authentification auth =
                                  Provider.of<Authentification>(context,
                                      listen: false);
                              if (data.exists) {
                                user = UserDetails.fromDocuments(data);
                                auth.user = user!;
                                auth.isAuthentificated = true;
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                prefs.setBool("isAuthentificated", true);
                                if (user!.pole == "Administrateurs") {
                                  prefs.setBool("isAdmin", true);
                                } else {
                                  prefs.setBool("isAdmin", false);
                                }
                                prefs.setString("pole", user!.pole!);
                                prefs.setString(
                                    "identifiant", user!.identifiant!);
                                prefs.setString("nom", user!.nom!);
                                prefs.setString("prenom", user!.prenom!);
                                prefs.setString("email", user!.email!);
                                prefs.setString("tel", user!.tel!);
                                prefs.setString("grade", user!.grade!);
                                prefs.setString("imageUrl", user!.imageUrl!);

                                if (user!.identifiant == _password.text) {
                                  await FirebaseFirestore.instance
                                      .collection("Users")
                                      .doc(id)
                                      .set({"status": true},
                                          SetOptions(merge: true));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(login);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => HomeScreen()),
                                  );
                                } else {
                                  print("Incorrect Password");
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(wrong_pass);
                                }
                              } else {
                                print("user not found");
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(user_not_found);
                              }

                              /*await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: _identifiant.text.trim() +
                                          "@telnet.tn",
                                      password: _password.text.trim());*/
                              //setState(() {});
                              //User? user = FirebaseAuth.instance.currentUser;
                              /*if (user != null) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          HomeScreen(user: user)),
                                );
                              }*/
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(empty_fields);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.blue,
                            ),
                            alignment: Alignment.center,
                            height: size.height / 15,
                            width: size.width / 1.5,
                            child: Text(
                              "Se Connecter",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(Size size, String hintText, IconData icon, bool password,
      TextEditingController controller) {
    return Container(
      height: size.height / 15,
      width: size.width / 1.1,
      child: TextFormField(
        controller: controller,
        obscureText: password ? _obscureText : false,
        decoration: InputDecoration(
          errorBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
            borderSide: BorderSide(
              color: Colors.red,
            ),
          ),
          prefixIcon: Icon(icon),
          suffixIcon: password
              ? GestureDetector(
                  child: Icon(Icons.remove_red_eye),
                  onTap: () {
                    _toggle();
                  },
                )
              : null,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
