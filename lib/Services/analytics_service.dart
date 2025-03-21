import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all dashboard statistics in a single method
  Future<Map<String, dynamic>> getDashboardStats() async {
    // Get user counts by role
    final usersSnapshot = await _firestore.collection('users').get();
    
    int studentCount = 0;
    int lecturerCount = 0;
    int adminCount = 0;
    
    for (var doc in usersSnapshot.docs) {
      final role = doc.data()['role'] as String?;
      if (role == 'student') {
        studentCount++;
      } else if (role == 'lecturer') {
        lecturerCount++;
      } else if (role == 'admin') {
        adminCount++;
      }
    }
    
    // Get courses count
    final coursesSnapshot = await _firestore.collection('courses').get();
    final coursesCount = coursesSnapshot.docs.length;
    
    // Get course details with student counts
    List<Map<String, dynamic>> courses = [];
    
    for (var courseDoc in coursesSnapshot.docs) {
      final courseData = courseDoc.data();
      
      // Get enrolled students for this course
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseDoc.id)
          .get();
      
      courses.add({
        'id': courseDoc.id,
        'name': courseData['name'] ?? 'Unnamed Course',
        'code': courseData['courseCode'] ?? '',
        'lecturer': courseData['lecturerName'] ?? 'Unknown',
        'studentsCount': enrollmentsSnapshot.docs.length,
      });
    }
    
    return {
      'stats': {
        'students': studentCount,
        'lecturers': lecturerCount,
        'courses': coursesCount,
        'activeUsers': studentCount + lecturerCount + adminCount,
      },
      'coursesList': courses,
    };
  }
  
  // Stream version for real-time updates
  Stream<Map<String, dynamic>> dashboardStatsStream() {
    // This is a more complex implementation that combines multiple streams
    // You would need to use Rx operators like combineLatest from rxdart package
    // For now, let's use the simpler approach with a periodic refresh
    
    return Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => getDashboardStats());
  }
}

// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Provider for dashboard stats
final dashboardStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.dashboardStatsStream();
});