import 'package:attendanceweb/Features/Models/client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static var instance;

  static Future<Client> getClientData(String email) async {
    final QuerySnapshot querySnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    final List<QueryDocumentSnapshot> docs = querySnapshot.docs;
    return docs
        .map((doc) => Client.fromJson(doc.data() as Map<String, dynamic>))
        .toList()
        .first;
  }

  static Future<void> saveClientData( Client client) async {
    final DocumentReference docRef = firestore.collection('users').doc();
    await docRef.set(client.toJson());
  }
}
