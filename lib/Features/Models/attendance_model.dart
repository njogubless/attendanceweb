class AttendanceModel {
  final String id;
  final String courseId;
  final String date;
  final List<String> presentStudents;
  final List<String> absentStudents;
  final String lecturerId;
  final Map<String, dynamic> additionalData;
  final String status;

  AttendanceModel({
    required this.id,
    required this.courseId,
    required this.date,
    required this.presentStudents,
    required this.absentStudents,
    required this.lecturerId,
    this.additionalData = const {},
    required this.status,
});
  
  factory AttendanceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      courseId: data['courseId'] ?? '',
      date: data['date'] ?? '',
      presentStudents: List<String>.from(data['presentStudents'] ?? []),
      absentStudents: List<String>.from(data['absentStudents'] ?? []),
      lecturerId: data['lecturerId'] ?? '',
      additionalData: data['additionalData'] ?? {},
      status: data['status'] ?? '',
    );
}
  
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'date': date,
      'presentStudents': presentStudents,
      'absentStudents': absentStudents,
      'lecturerId': lecturerId,
      'additionalData': additionalData,
      'status': status,
    };
 }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      date: map['date'] ?? '',
      presentStudents: List<String>.from(map['presentStudents'] ?? []),
      absentStudents: List<String>.from(map['absentStudents'] ?? []),
      lecturerId: map['lecturerId'] ?? '',
      additionalData: map['additionalData'] ?? {},
      status: map['status'] ?? '',
    );
  }


   AttendanceModel copyWith({
    String? id,
    String? courseId,
    List<String>? presentStudents,
    List<String>? absentStudents,
    String? lecturerId,
    String? date,
    String? status,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      presentStudents: presentStudents ?? this.presentStudents,
      absentStudents: absentStudents ?? this.absentStudents,
      lecturerId: lecturerId ?? this.lecturerId,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

}