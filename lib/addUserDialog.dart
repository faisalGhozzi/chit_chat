import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chatnet/main.dart';
import 'package:chatnet/model/user.dart';
import 'package:chatnet/repertoireScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_dropdown/smart_dropdown.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  List<SmartDropdownMenuItem> items = [];
  List<SmartDropdownMenuItem> items2 = [];
  SmartDropdownMenuItem getItem(dynamic value, String item) {
    return SmartDropdownMenuItem(
        value: value,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(item),
        ));
  }

  String? _selectedPole;
  String? _selectedGrade;

  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  _imgFromGallery() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  Future<UserDetails> getUser() async {
    final Authentification auth =
        Provider.of<Authentification>(context, listen: true);

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
      auth.user = u;
      return auth.user;
    }
    return UserDetails();
  }

  Future<String> uploadFile(String filePath, String name) async {
    File file = File(filePath);
    await FirebaseAuth.instance.signInAnonymously();

    try {
      await FirebaseStorage.instance.ref('images/$name').putFile(file);
      String downloadURL =
          await FirebaseStorage.instance.ref('images/$name').getDownloadURL();
      await FirebaseAuth.instance.signOut();
      print(downloadURL);
      return downloadURL;
    } on FirebaseException catch (e) {
      print(e.toString());
      // e.g, e.code == 'canceled'
    }
    return '';
  }

  Future sendEmail(
      {required String email,
      required String nom,
      required String prenom,
      required String message}) async {
    final serviceId = 'service_miofg1f';
    final templateId = 'template_8mj96eg';
    final userId = 'user_SeJ12Jwh9S6oR8lWmOcPd';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'user_name': prenom,
            'user_email': email,
            'message': message
          }
        }));
  }

  TextEditingController email = TextEditingController();
  TextEditingController identifiant = TextEditingController();
  TextEditingController nom = TextEditingController();
  TextEditingController prenom = TextEditingController();
  TextEditingController telephone = TextEditingController();
  final empty_fields = SnackBar(
    content: Text('Veuillez remplir Tous les champs !'),
    elevation: 100.0,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(bottom: 30, left: 10, right: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
    backgroundColor: Colors.blue.shade300,
  );

  final added_user = SnackBar(
    content: Text('Utilisateur Ajouté avec succés !'),
    elevation: 100.0,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(bottom: 30, left: 10, right: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
    backgroundColor: Colors.blue.shade300,
  );
  @override
  Widget build(BuildContext context) {
    items = [
      getItem("R&D", "R&D"),
      getItem("Pôle Télécom & Intégration Réseaux",
          "Pôle Télécom & Intégration Réseaux"),
      getItem("Pôle Services PLM & Etudes Mécaniques",
          "Pôle Services PLM & Etudes Mécaniques"),
      getItem("Adminstrateurs", "Adminstrateurs"),
    ];
    items2 = [
      getItem("employé(e)", "employé(e)"),
      getItem("Directeur", "Directeur"),
      getItem("Chef", "Chef"),
      getItem("Stagiaire", "Stagiaire"),
    ];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Ajouter un Utilisateur"),
      ),
      body: Center(
        child: Column(
          children: [
            Stack(children: [
              Container(
                margin: EdgeInsets.only(top: 48),
                height: 0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    child: CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 12.0,
                              child: Icon(
                                Icons.camera_alt,
                                size: 15.0,
                                color: Color(0xFF404040),
                              ),
                            ),
                            onTap: () {
                              _imgFromGallery();
                            },
                          ),
                        ),
                        radius: 38.0,
                        backgroundImage: _image?.name != null
                            ? FileImage(File(_image!.path)) as ImageProvider
                            : AssetImage('images/user_default.png'),
                      ),
                    ),
                  )),
            ]),
            Center(
              child: Form(
                child: Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: email,
                          decoration: InputDecoration(
                            errorBorder: UnderlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            hintText: "Email",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              fit: FlexFit.loose,
                              child: TextFormField(
                                controller: nom,
                                decoration: InputDecoration(
                                  errorBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                    borderSide: BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  hintText: "Nom",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: TextFormField(
                                controller: prenom,
                                decoration: InputDecoration(
                                  errorBorder: UnderlineInputBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                    borderSide: BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  hintText: "Prénom",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: telephone,
                          decoration: InputDecoration(
                            errorBorder: UnderlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            hintText: "Téléphone",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Pôle")),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 50,
                          child: SmartDropDown(
                            defaultSelectedIndex: 0,
                            items: items,
                            borderRadius: 5,
                            borderColor: Theme.of(context).primaryColor,
                            expandedColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _selectedPole = value;
                              });
                              //print(value);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Grade")),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 50,
                          child: SmartDropDown(
                            defaultSelectedIndex: 0,
                            items: items2,
                            borderRadius: 5,
                            borderColor: Theme.of(context).primaryColor,
                            expandedColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _selectedGrade = value;
                              });
                              //print(value);
                            },
                          ),
                        ),
                      ),
                      Container(
                          width: 250,
                          child: ElevatedButton(
                              onPressed: () async {
                                if (email.text.isNotEmpty &&
                                    nom.text.isNotEmpty &&
                                    prenom.text.isNotEmpty &&
                                    telephone.text.isNotEmpty) {
                                  var r = Random();
                                  const _chars =
                                      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
                                  String identifiant = List.generate(
                                          5,
                                          (index) =>
                                              _chars[r.nextInt(_chars.length)])
                                      .join();
                                  String? id = email.text
                                      .trim()
                                      .substring(
                                          0, email.text.trim().indexOf("@"))
                                      .toString();
                                  String? imageUrl;
                                  if (_image != null) {
                                    imageUrl = await uploadFile(
                                        _image!.path, _image!.name);
                                  }
                                  await FirebaseFirestore.instance
                                      .collection("Users")
                                      .doc(id)
                                      .set({
                                    "email": email.text,
                                    "tel": telephone.text,
                                    "pole": _selectedPole,
                                    "nom": nom.text,
                                    "prenom": prenom.text,
                                    "imageUrl": imageUrl != null
                                        ? imageUrl
                                        : 'https://firebasestorage.googleapis.com/v0/b/chatnet-aee6c.appspot.com/o/images%2Fuser_default.png?alt=media&token=e28a7148-dd6c-4434-a973-d3030102ea33',
                                    "identifiant": identifiant,
                                    "grade": _selectedGrade.toString(),
                                    "status": false,
                                    "typingTo": ""
                                  });
                                  sendEmail(
                                      email: email.text,
                                      nom: nom.text,
                                      prenom: prenom.text,
                                      message:
                                          'Email : ${email.text} \n Identifiant : $identifiant \n ');
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Repertoire()),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(added_user);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(empty_fields);
                                }
                              },
                              child: Text("Ajouter")))
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
