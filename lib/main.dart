import 'package:chatnet/loginScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/user.dart';

class Authentification with ChangeNotifier {
  bool _isAuthentificated = false;
  UserDetails? _user;

  clear() {
    this._isAuthentificated = false;
    this._user = null;
  }

  UserDetails get user {
    return this._user!;
  }

  set user(UserDetails user) {
    this._user = user;
    notifyListeners();
  }

  bool get isAuthentificated {
    return this._isAuthentificated;
  }

  set isAuthentificated(bool newVal) {
    this._isAuthentificated = newVal;
    this.notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Authentification>(
          create: (final BuildContext context) {
            return Authentification();
          },
        )
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<Authentification>(
      builder: (final BuildContext context,
          final Authentification authentification, final Widget? child) {
        return MaterialApp(
          theme:
              ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
        );
      },
    );
  }
}
