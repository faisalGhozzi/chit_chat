import 'package:chatnet/Signaling.dart';
import 'package:chatnet/model/user.dart';
import 'package:chatnet/otherProfileScreen.dart';
import 'package:chatnet/size_config.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_incall/flutter_incall.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

const kBackgoundColor = Color(0xFF091C40);
const kSecondaryColor = Color(0xFF606060);
const kRedColor = Color(0xFFFF1E46);

class Voice extends StatefulWidget {
  final String? roomId;
  final UserDetails? caller;
  final UserDetails? callee;
  final Signaling signaling;

  Voice(
      {Key? key,
      this.roomId,
      this.caller,
      this.callee,
      required this.signaling})
      : super(key: key);

  @override
  _VoiceState createState() => _VoiceState();
}

class _VoiceState extends State<Voice> {
  @override
  Widget build(BuildContext context) {
    return calling(
        context, widget.roomId, widget.caller, widget.callee, widget.signaling);
  }
}

Widget calling(BuildContext context, String? roomId, UserDetails? caller,
    UserDetails? callee, Signaling signaling) {
  SizeConfig().init(context);
  return Scaffold(
    backgroundColor: kBackgoundColor,
    body: Body(roomId, caller, callee, signaling),
  );
}

Widget call() {
  return Container();
}

Widget callRecieved() {
  return Container();
}

class Body extends StatefulWidget {
  Body(this.roomId, this.caller, this.callee, this.signaling);
  final String? roomId;
  final UserDetails? caller;
  final UserDetails? callee;
  final Signaling signaling;

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  IncallManager incallManager = new IncallManager();
  SignalingState? _callState;
  bool muted = false;
  bool cameraActivationStatus = false;
  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    widget.signaling.openUserMediaVideo(_localRenderer, _remoteRenderer);

    widget.signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      //signaling.openUserMediaAudio(_localRenderer, _remoteRenderer);
      //checkCall(widget.roomId);
      setState(() {});
    });

    super.initState();

    widget.signaling.checkCall(widget.roomId);
    _connect();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _connect() {
    widget.signaling.onStateChange = (SignalingState state, String roomId) {
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
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;
            _callState = state;
          });

          //incallManager.stopRingtone();
          //incallManager.stop(busytone: '_DTMF_');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => OtherProfile(
                      email: widget.callee!.email,
                      grade: widget.callee!.grade,
                      imageUrl: widget.callee!.imageUrl,
                      nom: widget.callee!.nom,
                      pole: widget.callee!.pole,
                      prenom: widget.callee!.prenom,
                      status: widget.callee!.status,
                      tel: widget.callee!.tel,
                    )),
          );
          break;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kBackgoundColor,
        body: FutureBuilder<Widget>(
          future: _callState == SignalingState.CallStateOutgoing
              ? onGoingCallWidget(context)
              : _callState == SignalingState.CallStateIncoming
                  ? incomingCallWidget(context)
                  : _callState == SignalingState.CallStateConnected
                      ? call()
                      : test(),
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

  Future<Widget> call() async {
    return SafeArea(
      child: Column(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: RTCVideoView(
                    _localRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: true,
                  )),
                  Expanded(
                      child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )),
                ],
              ),
            ),
          ),
          Spacer(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              DialButton(
                iconSrc: "images/Icon Mic.svg",
                text: "Audio",
                press: () async {
                  muted = widget.signaling
                      .toggleMicActivation(_localRenderer.srcObject!, muted);
                  setState(() {});
                },
              ),
              DialButton(
                iconSrc: "images/Icon Video.svg",
                text: "Video",
                press: () async {
                  cameraActivationStatus = widget.signaling
                      .toggleCameraActivation(
                          _localRenderer.srcObject!, cameraActivationStatus);
                  setState(() {});
                },
              ),
            ],
          ),
          VerticalSpacing(),
          RoundedButton(
            iconSrc: "images/call_end.svg",
            press: () {
              //incallManager.stopRingtone();
              //incallManager.stop(busytone: "_DTMF_");
              widget.signaling.hangUp(_localRenderer, widget.roomId);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => OtherProfile(
                          email: widget.callee!.email,
                          grade: widget.callee!.grade,
                          imageUrl: widget.callee!.imageUrl,
                          nom: widget.callee!.nom,
                          pole: widget.callee!.pole,
                          prenom: widget.callee!.prenom,
                          status: widget.callee!.status,
                          tel: widget.callee!.tel,
                        )),
              );
            },
            color: kRedColor,
            iconColor: Colors.white,
          ),
          SizedBox(height: 8)
        ],
      ),
    );
  }

  Future<Widget> test() async {
    return Container();
  }

  Future<Widget> onGoingCallWidget(BuildContext context) async {
    incallManager.checkRecordPermission();
    incallManager.requestRecordPermission();
    incallManager.checkCameraPermission();
    incallManager.requestCameraPermission();

    await widget.signaling.createRoom(_remoteRenderer, widget.roomId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              widget.callee!.prenom! + " " + widget.callee!.nom!,
              style: Theme.of(context)
                  .textTheme
                  .headline4!
                  .copyWith(color: Colors.white),
            ),
            Text(
              "Appel en cours…",
              style: TextStyle(color: Colors.white60),
            ),
            VerticalSpacing(),
            DialUserPic(image: widget.callee!.imageUrl),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    )),
                    Expanded(
                        child: RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )),
                  ],
                ),
              ),
            ),
            Spacer(),
            VerticalSpacing(),
            RoundedButton(
              iconSrc: "images/call_end.svg",
              press: () {
                /* May generate app crash  */
                incallManager.stopRingtone();
                incallManager.stop(busytone: "_DTMF_");
                widget.signaling.hangUp(_localRenderer, widget.roomId);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OtherProfile(
                            email: widget.callee!.email,
                            grade: widget.callee!.grade,
                            imageUrl: widget.callee!.imageUrl,
                            nom: widget.callee!.nom,
                            pole: widget.callee!.pole,
                            prenom: widget.callee!.prenom,
                            status: widget.callee!.status,
                            tel: widget.callee!.tel,
                          )),
                );
              },
              color: kRedColor,
              iconColor: Colors.white,
            )
          ],
        ),
      ),
    );
  }

  Future<Widget> incomingCallWidget(BuildContext context) async {
    incallManager.checkRecordPermission();
    incallManager.requestRecordPermission();
    incallManager.checkCameraPermission();
    incallManager.requestCameraPermission();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              widget.callee!.prenom! + " " + widget.callee!.nom!,
              style: Theme.of(context)
                  .textTheme
                  .headline4!
                  .copyWith(color: Colors.white),
            ),
            Text(
              "Vous appelle…",
              style: TextStyle(color: Colors.white60),
            ),
            VerticalSpacing(),
            DialUserPic(image: widget.callee!.imageUrl),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    )),
                    Expanded(
                        child: RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 150,
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                RoundedButton(
                  iconSrc: "images/call.svg",
                  press: () async {
                    await widget.signaling
                        .joinRoom(widget.roomId!, _remoteRenderer);
                  },
                  color: Colors.green,
                  iconColor: Colors.white,
                ),
                SizedBox(
                  width: 50,
                ),
                RoundedButton(
                  iconSrc: "images/call_end.svg",
                  press: () {
                    /* may generate app crash  */
                    incallManager.stopRingtone();
                    incallManager.stop(busytone: "_DTMF_");
                    widget.signaling.hangUp(_localRenderer, widget.roomId);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OtherProfile(
                                email: widget.callee!.email,
                                grade: widget.callee!.grade,
                                imageUrl: widget.callee!.imageUrl,
                                nom: widget.callee!.nom,
                                pole: widget.callee!.pole,
                                prenom: widget.callee!.prenom,
                                status: widget.callee!.status,
                                tel: widget.callee!.tel,
                              )),
                    );
                  },
                  color: kRedColor,
                  iconColor: Colors.white,
                )
              ],
            ),
          ],
        ),
      ),
    );
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
