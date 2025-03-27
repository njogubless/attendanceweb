import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String? studentId;
  final String? studentName;
  final String courseId;
  final String? courseName;
  final String? unitId;
  final String lecturerId;
  final DateTime attendanceDate;
  final String? venue;
  final String status;
  final String? lecturerComments;
  final List<String> presentStudents;
  final List<String> absentStudents;
  final Map<String, dynamic> additionalData;

  AttendanceModel({
    required this.id,
    this.studentId,
    this.studentName,
    required this.courseId,
    this.courseName,
    this.unitId,
    required this.lecturerId,
    required this.attendanceDate,
    this.venue,
    required this.status,
    this.lecturerComments,
    this.presentStudents = const [],
    this.absentStudents = const [],
    this.additionalData = const {},
  });

  // Factory constructor from Firestore
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic> ?? {};
  return AttendanceModel(
    id: doc.id,
    studentId: data['studentId'],
    studentName: data['studentName'],
    courseId: data['courseId'] ?? '',
    courseName: data['courseName'],
    unitId: data['unitId'],
    lecturerId: data['lecturerId'] ?? '',
    attendanceDate: data['attendanceDate'] is Timestamp
        ? (data['attendanceDate'] as Timestamp).toDate()
        : DateTime.now(),
    venue: data['venue'],
    status: data['status'] ?? '',
    lecturerComments: data['lecturerComments'],
    presentStudents: List<String>.from(data['presentStudents'] ?? []),
    absentStudents: List<String>.from(data['absentStudents'] ?? []),
    additionalData: data['additionalData'] ?? {},
  );
}

  // Factory constructor from Map
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      studentId: map['studentId'],
      studentName: map['studentName'],
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'],
      unitId: map['unitId'],
      lecturerId: map['lecturerId'] ?? '',
      attendanceDate: map['attendanceDate'] is DateTime
          ? map['attendanceDate']
          : DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      venue: map['venue'],
      status: map['status'] ?? '',
      lecturerComments: map['lecturerComments'],
      presentStudents: List<String>.from(map['presentStudents'] ?? []),
      absentStudents: List<String>.from(map['absentStudents'] ?? []),
      additionalData: map['additionalData'] ?? {},
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'unitId': unitId,
      'lecturerId': lecturerId,
      'attendanceDate': attendanceDate,
      'venue': venue,
      'status': status,
      'lecturerComments': lecturerComments,
      'presentStudents': presentStudents,
      'absentStudents': absentStudents,
      'additionalData': additionalData,
    };
  }

  // CopyWith method for easy modification
  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    String? unitId,
    String? lecturerId,
    DateTime? attendanceDate,
    String? venue,
    String? status,
    String? lecturerComments,
    List<String>? presentStudents,
    List<String>? absentStudents,
    Map<String, dynamic>? additionalData,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      unitId: unitId ?? this.unitId,
      lecturerId: lecturerId ?? this.lecturerId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      lecturerComments: lecturerComments ?? this.lecturerComments,
      presentStudents: presentStudents ?? this.presentStudents,
      absentStudents: absentStudents ?? this.absentStudents,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}