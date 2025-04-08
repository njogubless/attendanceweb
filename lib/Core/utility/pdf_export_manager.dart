import 'package:attendanceweb/Core/utility/pdf_service.dart';
import 'package:attendanceweb/Core/utility/preview_screen.dart';
import 'package:attendanceweb/Features/Models/attendance_model.dart';

import 'package:flutter/material.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:share_plus/share_plus.dart';

class PdfExportManager {
  List<AttendanceModel> _studentAttendances = [];
  Map<String, List<AttendanceModel>> _lecturerAttendances = {};
    List<Map<String, dynamic>> _studentRecords = [];
  
  bool get hasStudentData => _studentAttendances.isNotEmpty;
  bool get hasLecturerData => _lecturerAttendances.isNotEmpty;


   void setStudentRecords(List<Map<String, dynamic>> records) {
    _studentRecords = records;
  }
  
  void setStudentAttendances(List<AttendanceModel> attendances) {
    _studentAttendances = attendances;
  }
  
  void setLecturerAttendances(Map<String, List<AttendanceModel>> attendances) {
    _lecturerAttendances = attendances;
  }
  
  // Convert AttendanceModel list to map list for PDF service
  List<Map<String, dynamic>> _convertStudentAttendancesToMaps() {
    return _studentAttendances.map((a) => a.toMap()).toList();
  }
  
  // Convert lecturer attendances structure to format needed by PDF service
  Map<String, List<Map<String, dynamic>>> _convertLecturerAttendancesToMaps() {
    Map<String, List<Map<String, dynamic>>> result = {};
    
    _lecturerAttendances.forEach((lecturerId, attendances) {
      result[lecturerId] = attendances.map((a) => a.toMap()).toList();
    });
    
    return result;
  }
  
  // Generate appropriate PDF based on type
  Future<pw.Document> _generatePdf({required bool isStudent}) async {
    if (isStudent) {
      return await AttendancePdfService.generateStudentAttendancePdf(
        _convertStudentAttendancesToMaps()
      );
    } else {
      return await AttendancePdfService.generateLecturerAttendancePdf(
        _convertLecturerAttendancesToMaps()
      );
    }
  }
  
  // Get appropriate filename based on type
  String _getFileName({required bool isStudent}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return isStudent 
        ? 'student_attendance_$timestamp.pdf'
        : 'lecturer_attendance_$timestamp.pdf';
  }
  
  // Open PDF preview screen
  Future<void> previewPdf(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      final title = isStudent ? 'Student Attendance Report' : 'Lecturer Attendance Report';
      final fileName = _getFileName(isStudent: isStudent);
      
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdf: pdf,
            title: title,
            fileName: fileName,
          ),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar(context, 'Failed to generate PDF preview');
    }
  }
  
  // Save PDF to device
  Future<void> savePdfToDevice(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      final fileName = _getFileName(isStudent: isStudent);
      
      final file = await AttendancePdfService.savePdf(fileName, pdf);
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar(context, 'Failed to save PDF');
    }
  }
  
  // Share PDF
  Future<void> sharePdf(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      final fileName = _getFileName(isStudent: isStudent);
      final title = isStudent ? 'Student Attendance Report' : 'Lecturer Attendance Report';
      
      final file = await AttendancePdfService.savePdf(fileName, pdf);
      await Share.shareXFiles([XFile(file.path)], text: title);
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar(context, 'Failed to share PDF');
    }
  }
  
  // Print PDF
  Future<void> printPdf(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      final fileName = _getFileName(isStudent: isStudent);
      
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: fileName,
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar(context, 'Failed to print document');
    }
  }
  
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}