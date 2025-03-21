import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider for fetching user analytics data from Firestore
final userAnalyticsProvider = StreamProvider<Map<String, int>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((usersSnapshot) {
        // Count users by role
        int studentCount = 0;
        int lecturerCount = 0;
        int adminCount = 0;
        
        for (var userDoc in usersSnapshot.docs) {
          final role = userDoc.data()['role'] as String?;
          if (role == 'student') {
            studentCount++;
          } else if (role == 'lecturer') {
            lecturerCount++;
          } else if (role == 'admin') {
            adminCount++;
          }
        }
        
        // Count courses
        return FirebaseFirestore.instance
            .collection('courses')
            .get()
            .then((coursesSnapshot) {
              final totalCourses = coursesSnapshot.docs.length;
              
              return {
                'students': studentCount,
                'lecturers': lecturerCount,
                'admins': adminCount,
                'courses': totalCourses,
                'activeUsers': studentCount + lecturerCount + adminCount,
              };
            });
      }).asyncMap((future) => future);
});

// Provider for courses data
final coursesDataProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('courses')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            
            return {
              'name': data['name'] ?? 'Unnamed Course',
              'code': data['courseCode'] ?? '',
              'lecturer': data['lecturerName'] ?? 'Unknown',
              // Get enrolled students count from the enrollments collection
              'studentsCount': getEnrollmentCount(doc.id),
            };
          }).toList());
});

// Helper function to get enrollment count for a course
Future<int> getEnrollmentCount(String courseId) async {
  final enrollmentsSnapshot = await FirebaseFirestore.instance
      .collection('enrollments')
      .where('courseId', isEqualTo: courseId)
      .get();
  
  return enrollmentsSnapshot.docs.length;
}