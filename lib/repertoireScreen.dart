import 'dart:io';

import 'package:chatnet/Firebase/FirebaseApi.dart';
import 'package:chatnet/addUserDialog.dart';
import 'package:chatnet/model/user.dart';
import 'package:chatnet/poleDetailsScreen.dart';
import 'package:dropdown_plus/dropdown_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Repertoire extends StatefulWidget {
  @override
  _RepertoireState createState() => _RepertoireState();
}

class _RepertoireState extends State<Repertoire> {
  var isDialOpen = ValueNotifier<bool>(false);
  var extend = false;
  var customDialRoot = false;
  var visible = true;
  var closeManually = false;
  var useRAnimation = true;
  var rmicons = false;
  // ignore: todo
  //  TODO : get isAdmin from user
  var speedDialDirection = SpeedDialDirection.Up;
  var selectedfABLocation = FloatingActionButtonLocation.endDocked;
  var switchLabelPosition = false;
  var renderOverlay = true;
  bool? isAdmin = false;
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  String? _selectedKey = "";
  UserDetails? user;

  List<String> keys = <String>[
    'R&D',
    'Pôle Télécom & Intégration Réseaux',
    'Pôle Services PLM & Etudes Mécaniques',
    'Adminstrateurs'
  ];

  Future<UserDetails?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var status = prefs.getBool('isAuthentificated') ?? false;

    if (status) {
      isAdmin = prefs.getBool("isAdmin");
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
    _selectedKey = keys[0];
    super.initState();
  }

  _imgFromCamera() async {
    XFile? image = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
    });
  }

  _imgFromGallery() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  Widget addUser() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(10),
      child: Center(
        child: Dialog(
          child: Column(
            children: [
              Stack(children: [
                Container(
                  margin: EdgeInsets.only(top: 48),
                  height: 50,
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
                                setState(() {
                                  _image = null;
                                });
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
                          child: TextFormField(
                            decoration: InputDecoration(
                              errorBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                              hintText: "Identifiant",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
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
                          padding: const EdgeInsets.all(10.0),
                          child: TextDropdownFormField(
                            options: [
                              "R&D",
                              "Pôle Télécom & Intégration Réseaux",
                              "Pôle Services PLM & Etudes Mécaniques",
                              "Adminstrateurs"
                            ],
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                                labelText: "Pôle"),
                            dropdownHeight: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<PoleCard> cards = [
      PoleCard(
        groupe: "R&D",
      ),
      PoleCard(
        groupe: "Pôle Télécom & Intégration Réseaux",
      ),
      PoleCard(
        groupe: "Pôle Services PLM & Etudes Mécaniques",
      ),
      PoleCard(
        groupe: "Administrateurs",
      ),
    ];
    return WillPopScope(
        onWillPop: () async {
          if (isDialOpen.value) {
            isDialOpen.value = false;
            return false;
          }
          return true;
        },
        child: FutureBuilder<UserDetails?>(
          future: getUser(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                  title: Text("Répertoire"),
                  leading: Container(),
                ),
                floatingActionButton: isAdmin!
                    ? SpeedDial(
                        icon: Icons.menu,
                        activeIcon: Icons.close,
                        spacing: 3,
                        openCloseDial: isDialOpen,
                        childPadding: EdgeInsets.all(5),
                        spaceBetweenChildren: 4,
                        dialRoot: customDialRoot
                            ? (ctx, open, toggleChildren) {
                                return ElevatedButton(
                                  onPressed: toggleChildren,
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.blue[900],
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 18),
                                  ),
                                  child: Text(
                                    "Custom Dial Root",
                                    style: TextStyle(fontSize: 17),
                                  ),
                                );
                              }
                            : null,
                        buttonSize: 56,
                        label: extend ? Text("Open") : null,
                        activeLabel: extend ? Text("Close") : null,
                        childrenButtonSize: 56.0,
                        visible: visible,
                        direction: speedDialDirection,
                        switchLabelPosition: switchLabelPosition,
                        renderOverlay: renderOverlay,
                        onOpen: () => print('OPENING DIAL'),
                        onClose: () => print('DIAL CLOSED'),
                        useRotationAnimation: useRAnimation,
                        tooltip: 'Open Speed Dial',
                        heroTag: 'speed-dial-hero-tag',
                        elevation: 8.0,
                        isOpenOnStart: false,
                        animationSpeed: 200,
                        shape: customDialRoot
                            ? RoundedRectangleBorder()
                            : StadiumBorder(),
                        children: [
                          SpeedDialChild(
                              child:
                                  !rmicons ? Icon(Icons.person_outline) : null,
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              label: 'Ajouter un utilisateur',
                              onTap: () => {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddUserScreen()),
                                    )
                                  }),
                        ],

                        /// If true user is forced to close dial manually
                        closeManually: closeManually,
                      )
                    : null,
                body: Container(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: cards.length,
                        itemBuilder: (BuildContext context, int index) {
                          return cards[index];
                        },
                      )
                    ],
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
        ));
  }
}

class PoleCard extends StatelessWidget {
  const PoleCard({Key? key, this.groupe = "", this.pole = ""})
      : super(key: key);

  final String groupe;
  final String pole;

  // PoleCard(this.groupe, {this.pole, this.users});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            customBorder:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              contentPadding:
                  EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
              title: Row(
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Text(groupe,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                ],
              ),
              trailing: FutureBuilder<List<UserDetails>>(
                future: FirebaseApi().getUsersPole(groupe),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text("${snapshot.data!.length}");
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
              ),
            ),
            onTap: () {
              print("Tapped Pole");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PoleDetails(groupe)),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
