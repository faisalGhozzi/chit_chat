import 'package:chatnet/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseApi {
  Future<List<UserDetails>> getUsers() async {
    List<UserDetails> users = [];
    QuerySnapshot data =
        await FirebaseFirestore.instance.collection("Users").get();
    if (data.size > 0) {
      data.docs.forEach((element) {
        users.add(UserDetails(
            identifiant: element.id,
            nom: element['nom'],
            prenom: element['prenom'],
            email: element['email'],
            tel: element['tel'],
            grade: element['grade'],
            imageUrl: element['imageUrl'],
            status: element['status'],
            pole: element['pole']));
      });
      return users;
    }

    return [];
  }

  Future<List<UserDetails>> getUsersPole(String pole) async {
    List<UserDetails> users = [];
    QuerySnapshot data =
        await FirebaseFirestore.instance.collection("Users").get();
    if (data.size > 0) {
      data.docs.forEach((element) {
        if (element['pole'] == pole) {
          users.add(UserDetails(
              identifiant: element.id,
              nom: element['nom'],
              prenom: element['prenom'],
              email: element['email'],
              tel: element['tel'],
              grade: element['grade'],
              imageUrl: element['imageUrl'],
              status: element['status'],
              pole: element['pole']));
        }
      });
      return users;
    }

    return [];
  }
}
