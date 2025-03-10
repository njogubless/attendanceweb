import 'package:attendanceweb/Features/Models/course_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all courses
  Stream<List<CourseModel>> getAllCourses() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourseModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
  
  // Get courses by lecturer
  Stream<List<CourseModel>> getCoursesByLecturer(String lecturerId) {
    return _firestore
        .collection('courses')
        .where('lecturerId', isEqualTo: lecturerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourseModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
  
  // Add new course
  Future<void> addCourse(CourseModel course) async {
    await _firestore.collection('courses').add(course.toMap());
  }
  
  // Update course
  Future<void> updateCourse(CourseModel course) async {
    await _firestore.collection('courses').doc(course.id).update(course.toMap());
  }
  
  // Delete course
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();
  }
}