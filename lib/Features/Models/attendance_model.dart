class AttendanceModel {
  final String id;
  final String courseId;
  final String date;
  final List<String> presentStudents;
  final List<String> absentStudents;
  final String lecturerId;
  final Map<String, dynamic> additionalData;
  
  AttendanceModel({
    required this.id,
    required this.courseId,
    required this.date,
    required this.presentStudents,
    required this.absentStudents,
    required this.lecturerId,
    this.additionalData = const {},
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
    };
  }
}