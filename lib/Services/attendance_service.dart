
import 'package:attendanceweb/Features/Models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get attendance records by course
  Stream<List<AttendanceModel>> getAttendanceByCourse(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['courseId'] = courseId; // Add course ID to the data
        return AttendanceModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }
  
  // Get all attendance records (flattened)
  Stream<List<AttendanceModel>> getAllAttendance() {
    // First, get all courses
    return _firestore.collection('courses').snapshots().asyncMap((coursesSnapshot) async {
      List<AttendanceModel> allAttendance = [];
      
      // For each course, get attendance records
      for (var courseDoc in coursesSnapshot.docs) {
        final String courseId = courseDoc.id;
        
        // Get attendance subcollection
        final attendanceSnapshot = await _firestore
            .collection('courses')
            .doc(courseId)
            .collection('attendance')
            .get();
            
        // Add each attendance record to our list
        for (var attendanceDoc in attendanceSnapshot.docs) {
          Map<String, dynamic> data = attendanceDoc.data();
          data['courseId'] = courseId; // Add course ID to the data
          allAttendance.add(AttendanceModel.fromFirestore(data, attendanceDoc.id));
        }
      }
      
      return allAttendance;
    });
  }
  
  // Add attendance record
  Future<void> addAttendance(AttendanceModel attendance) async {
    await _firestore
        .collection('courses')
        .doc(attendance.courseId)
        .collection('attendance')
        .add(attendance.toMap());
  }
  
  // Update attendance record
  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _firestore
        .collection('courses')
        .doc(attendance.courseId)
        .collection('attendance')
        .doc(attendance.id)
        .update(attendance.toMap());
  }
  
  // Delete attendance record
  Future<void> deleteAttendance(String courseId, String attendanceId) async {
    await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('attendance')
        .doc(attendanceId)
        .delete();
  }
}