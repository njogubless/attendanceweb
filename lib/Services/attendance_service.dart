import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendanceweb/Features/Models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get attendance records for a specific course with error handling
  Stream<List<AttendanceModel>> getCourseAttendance(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('attendances')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceModel.fromFirestore(doc);
      }).toList();
    });
  }

  Stream<List<AttendanceModel>> getAllAttendance() {
    return _firestore.collection('attendances').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Create new attendance record
  Future<String> createAttendance(AttendanceModel attendance) async {
    try {
      final docRef = await _firestore
          .collection('courses')
          .doc(attendance.courseId)
          .collection('attendances')
          .add(attendance.toMap());

      return docRef.id;
    } catch (e) {
      print('Error creating attendance: $e');
      rethrow;
    }
  }

  // Update existing attendance record
  Future<void> updateAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('courses')
          .doc(attendance.courseId)
          .collection('attendances')
          .doc(attendance.id)
          .update(attendance.toMap());
    } catch (e) {
      print('Error updating attendance: $e');
      rethrow;
    }
  }

  // Delete attendance record
  Future<void> deleteAttendance(String courseId, String attendanceId) async {
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('attendances')
          .doc(attendanceId)
          .delete();
    } catch (e) {
      print('Error deleting attendance: $e');
      rethrow;
    }
  }

  // Get attendance records for a specific student across all courses
 Stream<List<AttendanceModel>> getStudentAttendance(String studentId) {
  return _firestore
      .collection('attendances')
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();
  });
}
  // Get attendance statistics for a course
  Future<Map<String, dynamic>> getCourseAttendanceStats(String courseId) async {
    try {
      final attendanceSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('attendances')
          .get();

      final attendanceRecords = attendanceSnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      int totalSessions = attendanceRecords.length;
      int approvedSessions = attendanceRecords
          .where((record) => record.status.toLowerCase() == 'approved')
          .length;
      int pendingSessions = attendanceRecords
          .where((record) => record.status.toLowerCase() == 'pending')
          .length;
      int rejectedSessions = attendanceRecords
          .where((record) => record.status.toLowerCase() == 'rejected')
          .length;

      return {
        'totalSessions': totalSessions,
        'approvedSessions': approvedSessions,
        'pendingSessions': pendingSessions,
        'rejectedSessions': rejectedSessions,
        'approvalRate': totalSessions > 0
            ? (approvedSessions / totalSessions * 100).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      print('Error getting course attendance stats: $e');
      rethrow;
    }
  }

  // Bulk update attendance status for a specific course
  Future<void> bulkUpdateAttendanceStatus(
      String courseId, List<String> attendanceIds, String newStatus) async {
    try {
      final batch = _firestore.batch();

      for (String id in attendanceIds) {
        final docRef = _firestore
            .collection('courses')
            .doc(courseId)
            .collection('attendances')
            .doc(id);
        batch.update(docRef, {'status': newStatus});
      }

      await batch.commit();
    } catch (e) {
      print('Error in bulk status update: $e');
      rethrow;
    }
  }

  // Filter attendance by status for a specific course
  Stream<List<AttendanceModel>> filterCourseAttendanceByStatus(
      String courseId, String status) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('attendances')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceModel.fromFirestore(doc);
      }).toList();
    });
  }
}
