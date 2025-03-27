// import 'package:cloud_firestore/cloud_firestore.dart';

// class AttendanceModel {
//   final String? id;
//   final String? studentId;
//   final String? studentName;
//   final String? lecturerId;
//   final String? unitId;
//   final String? courseName;
//   final dynamic attendanceDate;
//   final String? venue;
//   final String? status;
//   final String? lecturerComments;

//   AttendanceModel({
//     this.id,
//     this.studentId,
//     this.studentName,
//     this.lecturerId,
//     this.unitId,
//     this.courseName,
//     this.attendanceDate,
//     this.venue,
//     this.status,
//     this.lecturerComments,
//   });

//   factory AttendanceModel.fromMap(Map<String, dynamic> map) {
//     return AttendanceModel(
//       id: map['id'],
//       studentId: map['studentId'],
//       studentName: map['studentName'],
//       lecturerId: map['lecturerId'],
//       unitId: map['unitId'],
//       courseName: map['courseName'],
//       attendanceDate: map['attendanceDate'],
//       venue: map['venue'],
//       status: map['status'],
//       lecturerComments: map['lecturerComments'],
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'studentId': studentId,
//       'studentName': studentName,
//       'lecturerId': lecturerId,
//       'unitId': unitId,
//       'courseName': courseName,
//       'attendanceDate': attendanceDate,
//       'venue': venue,
//       'status': status,
//       'lecturerComments': lecturerComments,
//     };
//   }
// }