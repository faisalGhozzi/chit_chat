import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? identifiant;
  final String? nom;
  final String? prenom;
  final String? imageUrl;
  final Timestamp? createdAt;
  final String? message;
  final String? type;
  final String? url;
  final String? fileName;

  const Message(
      {this.identifiant,
      this.nom,
      this.prenom,
      this.imageUrl,
      this.message,
      this.createdAt,
      this.type,
      this.url,
      this.fileName});

  factory Message.fromDocuments(DocumentSnapshot document) {
    return Message(
        identifiant: document.get('sendby'),
        message: document.get('message'),
        createdAt: document.get('time'),
        type: document.get('type'),
        url: document.get('url') == "" ? "" : document.get('url'),
        fileName:
            document.get('fileName') == "" ? "" : document.get('fileName'));
  }
  factory Message.fromDocument(DocumentSnapshot document) {
    return Message(
      identifiant: document.get('sendby'),
      message: document.get('message'),
      createdAt: document.get('time'),
      type: document.get('type'),
    );
  }
}
