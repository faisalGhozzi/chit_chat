import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  late String? identifiant;
  late String? nom;
  late String? prenom;
  late String? email;
  late String? tel;
  late String? grade;
  late String? pole;
  late String? imageUrl;
  late bool? status;
  late String? typingTo;

  UserDetails(
      {this.identifiant,
      this.nom,
      this.prenom,
      this.email,
      this.tel,
      this.grade,
      this.pole,
      this.imageUrl,
      this.status,
      this.typingTo});

  factory UserDetails.fromDocuments(DocumentSnapshot document) {
    return UserDetails(
        identifiant: document['identifiant'],
        nom: document['nom'],
        prenom: document['prenom'],
        email: document['email'],
        tel: document['tel'],
        grade: document['grade'],
        imageUrl: document['imageUrl'],
        status: document['status'],
        pole: document['pole'],
        typingTo: document['typingTo']);
  }

  //final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance.collection('users').snapshots();

  /* getUsers(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return ListTile(
              title: Text(data['full_name']),
              subtitle: Text(data['company']),
            );
          }).toList(),
        );
      },
    );
  } */

  @override
  String toString() {
    return 'UserDetails(identifiant: $identifiant, nom: $nom, prenom: $prenom, email: $email, tel: $tel, grade: $grade, pole: $pole, imageUrl: $imageUrl, status: $status, typingTo: $typingTo)';
  }
}



/** snapshot.data!.docs.map((DocumentSnapshot document) {
          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
          UserDetails u = UserDetails(
            identifiant: document.id,
            nom: data['nom'],
            prenom: data['prenom'],
            email: data['email'],
            pass: data['pass'],
            tel: data['tel'],
            grade: data['grade'],
            imageUrl: data['imageUrl'],
            status: data['status'],
          );
          users!.add(u);
          return ListTile();
        }).toList();
        return ListTile();
      }, */