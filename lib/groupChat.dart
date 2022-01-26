import 'dart:io';

import 'package:chatnet/Signaling.dart';
import 'package:chatnet/flutter_sound.dart';
import 'package:chatnet/model/user.dart';
import 'package:chatnet/public/demo_util/recorder_state.dart';
import 'package:chatnet/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_incall/flutter_incall.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'public/demo_util/demo_active_codec.dart';
import 'public/demo_util/temp_file.dart';

class GroupChat extends StatefulWidget {
  final String? chatroomId;
  final UserDetails? user;
  final UserDetails? authUser;

  GroupChat({this.chatroomId, this.user, this.authUser});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<GroupChat> {
  final TextEditingController _message = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool initialized = false;

  String? recordingFile;
  late Track track;
  String? audioUrl;

  Signaling signaling = Signaling();
  SignalingState? _callState;
  IncallManager incallManager = new IncallManager();

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool muted = false;
  bool cameraActivationStatus = false;

  UserDetails? authUser;

  @override
  void initState() {
    StreamBuilder(
      builder: (context, snapshot) {
        setState(() {});
        return Container();
      },
      stream: _connect(),
    );
    if (!kIsWeb) {
      var status = Permission.microphone.request();
      status.then((stat) {
        if (stat != PermissionStatus.granted) {
          throw RecordingPermissionException(
              'Microphone permission not granted');
        }
      });
    }
    super.initState();
    tempFile(suffix: '.aac').then((path) {
      recordingFile = path;
      track = Track(trackPath: recordingFile);
      setState(() {});
    });
  }

  Future<bool> init() async {
    if (!initialized) {
      await initializeDateFormatting();
      await UtilRecorder().init();
      ActiveCodec().recorderModule = UtilRecorder().recorderModule;
      ActiveCodec().setCodec(withUI: true, codec: Codec.aacADTS);

      initialized = true;
    }
    return initialized;
  }

  void _clean() async {
    if (recordingFile != null) {
      try {
        await File(recordingFile!).delete();
      } on Exception {
        // ignore
      }
    }
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

  @override
  void dispose() {
    _clean();
    super.dispose();
  }

  void onSendMessage() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> messages = {
        "message": _message.text,
        "time": FieldValue.serverTimestamp(),
        "type": "message"
      };

      _message.clear();
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('chats')
          .add(messages);
    } else {
      print("Say hi!");
    }
  }

  ScrollController _scroll = ScrollController();
  ScrollController _scrollEmojis = ScrollController();

  bool emojiShowing = false;

  XFile? _image;
  XFile? _file;
  final ImagePicker _picker = ImagePicker();

  _imgFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _image = XFile(result.files.single.path!);
      });
    } else {
      // User canceled the picker
    }
  }

  _fileFromPhone() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'PDF',
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt'
        ]);

    if (result != null) {
      setState(() {
        _file = XFile(result.files.single.path!);
        print(_file!.path);
      });
    } else {
      // User canceled the picker
    }
  }

  void onSendVoice() async {
    FocusScope.of(context).requestFocus(new FocusNode());

    if (track.trackPath != "") {
      String url = await uploadFile(track.trackPath!, "${Timestamp.now()}.mp3");
      audioUrl = url;

      Map<String, dynamic> messages = {
        "sendby": widget.authUser!.prenom,
        "message": "",
        "time": FieldValue.serverTimestamp(),
        "type": "audio",
        "url": url,
        "fileName": track.trackTitle
      };
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('chats')
          .add(messages);

      setState(() {});
    }
  }

  void onSendFile(String? url) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (_file!.path.isNotEmpty) {
      Map<String, dynamic> messages = {
        "sendby": widget.authUser!.prenom,
        "message": "",
        "time": FieldValue.serverTimestamp(),
        "type": "file",
        "url": url,
        "fileName": _file!.name
      };
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('chats')
          .add(messages);
    }
  }

  void onSendImage(String? url) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (_image!.path.isNotEmpty) {
      Map<String, dynamic> messages = {
        "sendby": widget.authUser!.prenom,
        "message": "",
        "time": FieldValue.serverTimestamp(),
        "type": "image",
        "url": url
      };
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('chats')
          .add(messages);
    }
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

  Future<void> downloadFile(String? name) async {
    await FirebaseAuth.instance.signInAnonymously();
    try {
      var ref = FirebaseStorage.instance.ref('images/$name');
      var data = await ref.getData();
      var localFile = XFile.fromData(
        data!,
      );
      final directory = await getApplicationDocumentsDirectory();
      print(directory);
      await localFile.saveTo(directory.path + Platform.pathSeparator + '$name');
      OpenFile.open(directory.path + Platform.pathSeparator + '$name');
      await FirebaseAuth.instance.signOut();
    } on FirebaseException catch (e) {
      print(e.toString());
      // e.g, e.code == 'canceled'
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _message
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _message.text.length));
  }

  void _onBackspacePressed() {
    _message
      ..text = _message.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _message.text.length));
  }

  void handleClick(String value) async {
    switch (value) {
      case 'Supprimer la Conversation':
        showDialog<void>(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Conversation'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: const <Widget>[
                    Text(
                        'Voudriez-vous vraiment supprimer cette conversation ?'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Oui'),
                  onPressed: () async {
                    var docRef = _firestore
                        .collection('chatrooms')
                        .doc(widget.chatroomId);
                    var messages = await docRef.collection('chats').get();
                    messages.docs.forEach((element) {
                      element.reference.delete();
                    });

                    Navigator.of(context).pop();
                    /* Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatsScreen()),
                    );*/
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

        break;
    }
  }

  Stream _connect() {
    signaling.onStateChange = (SignalingState state, String roomId) {
      switch (state) {
        case SignalingState.CallStateOutgoing:
          incallManager.start(
              media: MediaType.VIDEO, auto: false, ringback: '_DTMF_');
          this.setState(() {
            _callState = state;
          });
          break;
        case SignalingState.CallStateIncoming:
          incallManager.startRingtone(RingtoneUriType.DEFAULT, 'default', 30);
          this.setState(() {
            _callState = state;
          });
          break;
        case SignalingState.CallStateConnected:
          incallManager.stopRingback();
          incallManager.stopRingtone();
          incallManager.start(media: MediaType.VIDEO, auto: true, ringback: '');
          this.setState(() {
            _callState = state;
          });
          break;
        case SignalingState.CallStateIdle:
          this.setState(() {
            _callState = state;
          });

          break;
      }
    };
    return _callState as Stream;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: new Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            actions: <Widget>[],
            title: Container(
              child: Column(
                children: [
                  Text(widget.chatroomId!),
                ],
              ),
            )),
        body: FutureBuilder<Widget>(
          future: chat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
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

  Future<Widget> chat() async {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      controller: _scrollEmojis,
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Container(
              height: size.height / 1.30,
              width: size.width,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chatrooms')
                    .doc(widget.chatroomId)
                    .collection('chats')
                    .orderBy("time", descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      controller: _scroll,
                      physics: BouncingScrollPhysics(),
                      reverse: false,
                      shrinkWrap: true,
                      // primary: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> map = snapshot.data!.docs
                            .elementAt(index)
                            .data() as Map<String, dynamic>;

                        return messages(size, map, context);
                      },
                    );
                  } else {
                    return Text("Send new Messages !");
                  }
                },
              ),
            ),
          ),
          Container(
            height: size.height / 10,
            width: size.width / 0.5,
            alignment: Alignment.center,
            child: Container(
              height: size.height / 12,
              width: size.width / .5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: size.height,
                    width: size.width / 1.2,
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      controller: _message,
                      decoration: InputDecoration(
                          hintText: "Send Message",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: onSendMessage,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    emojiShowing = !emojiShowing;
                  });
                },
                icon: Icon(Icons.emoji_emotions_outlined),
                color: Colors.blueAccent,
              ),
              IconButton(
                icon: Icon(Icons.image_outlined),
                onPressed: () async {
                  _imgFromGallery();
                  String url = await uploadFile(_image!.path, _image!.name);
                  onSendImage(url);
                },
                color: Colors.blue,
              ),
              IconButton(
                icon: Icon(Icons.attachment_outlined),
                onPressed: () async {
                  _fileFromPhone();
                  String url = await uploadFile(_file!.path, _file!.name);
                  onSendFile(url);
                },
                color: Colors.blue,
              ),
              IconButton(
                icon: Icon(Icons.mic_outlined),
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Dialog(
                          child: SoundRecorderUI(
                            track,
                            recordingTitle: "",
                            stoppedTitle: "",
                            onStopped: (media) {
                              setState(() {
                                track = media.track;
                              });
                              onSendVoice();
                              Navigator.pop(context);
                              //print(track.trackPath);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                color: Colors.blue,
              ),
            ],
          ),
          Container(
            child: Offstage(
              offstage: !emojiShowing,
              child: SizedBox(
                height: 250,
                child: EmojiPicker(
                    onEmojiSelected: (Category category, Emoji emoji) {
                      _onEmojiSelected(emoji);
                    },
                    onBackspacePressed: _onBackspacePressed,
                    config: const Config(
                        columns: 7,
                        emojiSizeMax: 32.0,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        initCategory: Category.RECENT,
                        bgColor: Color(0xFFF2F2F2),
                        indicatorColor: Colors.blue,
                        iconColor: Colors.grey,
                        iconColorSelected: Colors.blue,
                        progressIndicatorColor: Colors.blue,
                        backspaceColor: Colors.blue,
                        showRecentsTab: true,
                        recentsLimit: 28,
                        noRecentsText: 'No Recents',
                        noRecentsStyle:
                            TextStyle(fontSize: 20, color: Colors.black26),
                        categoryIcons: CategoryIcons(),
                        buttonMode: ButtonMode.MATERIAL)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    var format = new DateFormat('hh:mm');
    return format.format(timestamp.toDate());
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    if (map['type'] == "message") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 10.0),

            ///Chat bubbles
            Container(
              padding: EdgeInsets.only(
                bottom: 5,
                right: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 40,
                      maxHeight: 250,
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      minWidth: MediaQuery.of(context).size.width * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 15, top: 10, bottom: 5, right: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              map['message'],
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          /*Icon(
                          Icons.done_all,
                          color: Colors.white,
                          size: 14,
                        )*/
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    map['time'] == null ? "..." : formatTimestamp(map['time']),
                    style: TextStyle(
                        fontSize: 12, color: Colors.black.withOpacity(0.5)),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (map['type'] == "file") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 10.0),

            ///Chat bubbles
            Container(
              padding: EdgeInsets.only(
                bottom: 5,
                right: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 40,
                      maxHeight: 250,
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      minWidth: MediaQuery.of(context).size.width * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 15, top: 10, bottom: 5, right: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () async {},
                            child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    Text(
                                      map['fileName'],
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          decorationStyle:
                                              TextDecorationStyle.solid,
                                          decoration: TextDecoration.underline,
                                          color: Colors.greenAccent),
                                    ),
                                    IconButton(
                                        onPressed: () async {
                                          var status =
                                              await Permission.storage.status;
                                          if (!status.isGranted) {
                                            if (await Permission.storage
                                                .request()
                                                .isGranted) {
                                              await downloadFile(
                                                  map['fileName']);
                                            }
                                          } else {
                                            await downloadFile(map['fileName']);
                                          }
                                        },
                                        icon: Icon(
                                            Icons.arrow_downward_outlined,
                                            color: Colors.white))
                                  ],
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    map['time'] == null ? "..." : formatTimestamp(map['time']),
                    style: TextStyle(
                        fontSize: 12, color: Colors.black.withOpacity(0.5)),
                  )
                ],
              ),
            ),

            SizedBox(width: 30.0),
          ],
        ),
      );
    }

    if (map['type'] == "image") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 10.0),

            ///Chat bubbles
            Container(
              padding: EdgeInsets.only(
                bottom: 5,
                right: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 40,
                      maxHeight: 250,
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      minWidth: MediaQuery.of(context).size.width * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 15, top: 10, bottom: 5, right: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                              padding: const EdgeInsets.all(5),
                              child: Container(
                                color: Colors.transparent,
                                width: 200,
                                height: 200,
                                child: PhotoView(
                                  initialScale:
                                      PhotoViewComputedScale.contained,
                                  imageProvider:
                                      NetworkImage(map['url'], scale: 10),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    map['time'] == null ? "..." : formatTimestamp(map['time']),
                    style: TextStyle(
                        fontSize: 12, color: Colors.black.withOpacity(0.5)),
                  )
                ],
              ),
            ),

            SizedBox(
                width: map['sendby'] == widget.authUser!.prenom ? 20.0 : 30.0),
          ],
        ),
      );
    }

    if (map['type'] == "audio") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 10.0),

            ///Chat bubbles
            Container(
              padding: EdgeInsets.only(
                bottom: 5,
                right: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 40,
                      maxHeight: 250,
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      minWidth: MediaQuery.of(context).size.width * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 15, top: 10, bottom: 5, right: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: SoundPlayerUI.fromLoader(
                              (BuildContext context) async {
                                var track = Track();
                                // validate codec for example file
                                if (ActiveCodec().codec != Codec.aacADTS) {
                                  var error = SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                          'You must set the Codec to MP3 to '
                                          'play the "Remote Example File"'));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(error);
                                } else {
                                  // We have to play an example audio file loaded via a URL
                                  track = Track(
                                      trackPath: map['url'],
                                      codec: ActiveCodec().codec!);

                                  track.trackTitle = 'Remote mpeg playback.';
                                  track.trackAuthor = 'By flutter_sound';

                                  if (kIsWeb) {
                                    track.albumArtAsset = null;
                                  } else if (Platform.isIOS) {
                                    track.albumArtAsset = 'AppIcon';
                                  } else if (Platform.isAndroid) {
                                    track.albumArtAsset = 'AppIcon.png';
                                  }
                                }

                                return track;
                              },
                              showTitle: false,
                              audioFocus: AudioFocus.requestFocusAndDuckOthers,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    map['time'] == null ? "..." : formatTimestamp(map['time']),
                    style: TextStyle(
                        fontSize: 12, color: Colors.black.withOpacity(0.5)),
                  )
                ],
              ),
            ),

            SizedBox(
                width: map['sendby'] == widget.authUser!.prenom ? 20.0 : 30.0),
          ],
        ),
      );
    }

    return Container();
  }
}

class DialButton extends StatelessWidget {
  const DialButton({
    @required this.iconSrc,
    @required this.text,
    @required this.press,
  });

  final String? iconSrc, text;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: getProportionateScreenWidth(120),
      child: FlatButton(
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenWidth(20),
        ),
        onPressed: press,
        child: Column(
          children: [
            SvgPicture.asset(
              iconSrc!,
              color: Colors.white,
              height: 36,
            ),
            VerticalSpacing(of: 5),
            Text(
              text!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DialUserPic extends StatelessWidget {
  const DialUserPic({
    this.size = 192,
    @required this.image,
  });

  final double? size;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(30 / 192 * size!),
      height: getProportionateScreenWidth(size!),
      width: getProportionateScreenWidth(size!),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.02),
            Colors.white.withOpacity(0.05)
          ],
          stops: [.5, 1],
        ),
      ),
      child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(100)),
          child: Image.network(
            image!,
            fit: BoxFit.cover,
          )),
    );
  }
}

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    this.size = 64,
    @required this.iconSrc,
    this.color = Colors.white,
    this.iconColor = Colors.black,
    @required this.press,
  });

  final double? size;
  final String? iconSrc;
  final Color? color, iconColor;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getProportionateScreenWidth(size!),
      width: getProportionateScreenWidth(size!),
      child: FlatButton(
        padding: EdgeInsets.all(15 / 64 * size!),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        color: color,
        onPressed: press,
        child: SvgPicture.asset(iconSrc!, color: iconColor),
      ),
    );
  }
}
