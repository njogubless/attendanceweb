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

 Stream<List<Client>> getUsersByRoleAndStatus(String role, String status) {
  Query query = firestore.collection('users').where('role', isEqualTo: role);
  
  if (status != 'all') {
    query = query.where('status', isEqualTo: status);
  }
  
  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      // Pass the entire doc, which is a DocumentSnapshot
      return Client.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
  });
}
  
  // Update user status
  Future<void> updateUserStatus(String userId, String newStatus) async {
    await firestore.collection('users').doc(userId).update({
      'status': newStatus,
    });
  }
  
  // Add new user
  Future<void> addUser(Client user) async {
    await firestore.collection('users').add(user.toMap());
  }
  
  // Delete user
  Future<void> deleteUser(String userId) async {
    await firestore.collection('users').doc(userId).delete();
  }

  
}
