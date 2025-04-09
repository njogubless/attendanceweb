import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String? studentId;
  final String? studentName;
  final String? studentEmail;
  final String? studentComments;
  final String courseId;
  final String? courseName;
  final String? unitId;
  final String lecturerId;
  final DateTime attendanceDate;
  final String? venue;
  final String status;
  final String? lecturerComments;
  final String? registrationNumber;
  final bool isSubmitted;
  final List<String> presentStudents;
  final List<String> absentStudents;
  final Map<String, dynamic> additionalData;

  AttendanceModel({
    required this.id,
    this.studentId,
    this.studentName,
    this.studentEmail,
    this.studentComments,
    required this.courseId,
    this.courseName,
    this.unitId,
    required this.lecturerId,
    required this.attendanceDate,
    this.venue,
    required this.status,
    this.lecturerComments,
    this.registrationNumber,
    this.isSubmitted = false,
    this.presentStudents = const [],
    this.absentStudents = const [],
    this.additionalData = const {},
  });

  // Factory constructor from Firestore
 factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  return AttendanceModel(
    id: doc.id,
    studentId: data['studentId'],
    studentName: data['studentName'],
    studentEmail: data['studentEmail'],
    studentComments: data['studentComments'],
    courseId: data['courseId'] ?? data['unitId'] ?? '', // Try both fields
    courseName: data['courseName'] ?? data['unitName'], // Try both fields
    unitId: data['unitId'],
    lecturerId: data['lecturerId'] ?? '',
    attendanceDate: data['attendanceDate'] is Timestamp
        ? (data['attendanceDate'] as Timestamp).toDate()
        : (data['date'] is Timestamp 
            ? (data['date'] as Timestamp).toDate() 
            : DateTime.now()),
    venue: data['venue'],
    status: data['status'] ?? 'pending',
    lecturerComments: data['lecturerComments'],
    registrationNumber: data['registrationNumber'],
    isSubmitted: data['isSubmitted'] ?? false,
    presentStudents: data['studentId'] != null 
        ? [data['studentId']] 
        : List<String>.from(data['presentStudents'] ?? []),
    absentStudents: List<String>.from(data['absentStudents'] ?? []),
    additionalData: Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => [
        'id', 'studentId', 'studentName', 'studentEmail', 'studentComments',
        'courseId', 'courseName', 'unitId', 'lecturerId', 'attendanceDate',
        'venue', 'status', 'lecturerComments', 'registrationNumber',
        'isSubmitted', 'presentStudents', 'absentStudents'
      ].contains(key)),
  );
}
  // Factory constructor from Map
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      studentId: map['studentId'],
      studentName: map['studentName'],
      studentEmail: map['studentEmail'],
      studentComments: map['studentComments'],
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
      registrationNumber: map['registrationNumber'],
      isSubmitted: map['isSubmitted'] ?? false,
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
      'studentEmail': studentEmail,
      'studentComments': studentComments,
      'courseId': courseId,
      'courseName': courseName,
      'unitId': unitId,
      'lecturerId': lecturerId,
      'attendanceDate': attendanceDate,
      'venue': venue,
      'status': status,
      'lecturerComments': lecturerComments,
      'registrationNumber': registrationNumber,
      'isSubmitted': isSubmitted,
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
    String? studentEmail,
    String? studentComments,
    String? courseId,
    String? courseName,
    String? unitId,
    String? lecturerId,
    DateTime? attendanceDate,
    String? venue,
    String? status,
    String? lecturerComments,
    String? registrationNumber,
    bool? isSubmitted,
    List<String>? presentStudents,
    List<String>? absentStudents,
    Map<String, dynamic>? additionalData,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      studentComments: studentComments ?? this.studentComments,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      unitId: unitId ?? this.unitId,
      lecturerId: lecturerId ?? this.lecturerId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      lecturerComments: lecturerComments ?? this.lecturerComments,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      presentStudents: presentStudents ?? this.presentStudents,
      absentStudents: absentStudents ?? this.absentStudents,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}