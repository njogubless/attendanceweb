import 'package:cloud_firestore/cloud_firestore.dart';

String formatDate(dynamic timestamp) {
  if (timestamp is Timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  } else if (timestamp is String) {
    return timestamp;
  }
  return 'Unknown';
}