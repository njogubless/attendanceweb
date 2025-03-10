class CourseModel {
  final String id;
  final String title;
  final String code;
  final String lecturerId;
  final List<String> enrolledStudents;
  final String description;
  final Map<String, dynamic> additionalData;
  
  CourseModel({
    required this.id,
    required this.title,
    required this.code,
    required this.lecturerId,
    required this.enrolledStudents,
    this.description = '',
    this.additionalData = const {},
  });
  
  factory CourseModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CourseModel(
      id: id,
      title: data['title'] ?? '',
      code: data['code'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      description: data['description'] ?? '',
      additionalData: data['additionalData'] ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      'lecturerId': lecturerId,
      'enrolledStudents': enrolledStudents,
      'description': description,
      'additionalData': additionalData,
    };
  }
}