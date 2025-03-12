import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String? uid;
  final String clientName;
  final String clientEmail;
  final String role;
  String? status;
  Client({
    required this.uid,
    required this.clientName,
    required this.clientEmail,
    required this.role,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'role': role,
      'status': status,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      uid: map['uid'] != null ? map['uid'] as String : null,
      clientName: map['clientName'] as String,
      clientEmail: map['clientEmail'] as String,
      role: map['role'] as String,
      status: map['status'] != null ? map['status'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Client.fromJson(Map<String, dynamic> map) {
    return Client(
      uid: map['uid'] != null ? map['uid'] as String : null,
      clientName: map['clientName'] as String,
      clientEmail: map['clientEmail'] as String,
      role: map['role'] as String,
      status: map['status'] != null ? map['status'] as String : null,
    );
  }
  factory Client.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, 
      [SnapshotOptions? options]) {
    final data = snapshot.data()!;
    return Client(
      uid: snapshot.id,
      clientName: data['clientName'] as String,
      clientEmail: data['clientEmail'] as String,
      role: data['role'] as String,
      status: data['status'] as String,
    );
  }
}
