import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfExportManager {
  // Student data
  List<Map<String, dynamic>> _studentRecords = [];
  List<Map<String, dynamic>> _studentAttendances = [];

  // Lecturer data
  List<Map<String, dynamic>> _lecturerRecords = [];
  List<Map<String, dynamic>> _lecturerAttendances = [];

  // Getters to check if there is data
  bool get hasStudentListData => _studentRecords.isNotEmpty;
  bool get hasStudentAttendanceData => _studentAttendances.isNotEmpty;
  bool get hasLecturerListData => _lecturerRecords.isNotEmpty;
  bool get hasLecturerAttendanceData => _lecturerAttendances.isNotEmpty;

  // Setters for student data
  void setStudentRecords(List<Map<String, dynamic>> records) {
    _studentRecords = records;
  }

  void setStudentAttendances(List<Map<String, dynamic>> attendances) {
    _studentAttendances = attendances;
  }

  // Setter for lecturer data
  void setLecturerRecords(List<Map<String, dynamic>> records) {
    _lecturerRecords = records;
  }

  void setLecturerAttendances(List<Map<String, dynamic>> attendances) {
    _lecturerAttendances = attendances;
  }

  // Helper methods to convert attendance objects to maps (if needed)
  List<Map<String, dynamic>> _convertStudentAttendancesToMaps() {
    // Just return the existing list if it's already in the right format
    return _studentAttendances;
  }

  List<Map<String, dynamic>> _convertLecturerAttendancesToMaps() {
    // Just return the existing list if it's already in the right format
    return _lecturerAttendances;
  }

  // Generate PDF document based on the data type
  Future<pw.Document> _generatePdf({required bool isStudent}) async {
    if (isStudent) {
      // Check if we're generating a student list report (not attendance)
      if (_studentAttendances.isEmpty && _studentRecords.isNotEmpty) {
        // Generate PDF from student records
        return await AttendancePdfService.generateStudentListPdf(_studentRecords);
      } else {
        // Generate PDF from student attendance records
        return await AttendancePdfService.generateStudentAttendancePdf(
          _convertStudentAttendancesToMaps()
        );
      }
    } else {
      // Check if we're generating a lecturer list report (not attendance)
      if (_lecturerAttendances.isEmpty && _lecturerRecords.isNotEmpty) {
        // Generate PDF from lecturer records
        return await AttendancePdfService.generateLecturerListPdf(_lecturerRecords);
      } else {
        // Generate PDF from lecturer attendance records
        return await AttendancePdfService.generateLecturerAttendancePdf(
          _convertLecturerAttendancesToMaps()
        );
      }
    }
  }

  // Helper method to create appropriate filename
  String _getFileName({required bool isStudent}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (isStudent) {
      return _studentAttendances.isEmpty && _studentRecords.isNotEmpty
          ? 'student_list_$timestamp.pdf'
          : 'student_attendance_$timestamp.pdf';
    } else {
      return _lecturerAttendances.isEmpty && _lecturerRecords.isNotEmpty
          ? 'lecturer_list_$timestamp.pdf'
          : 'lecturer_attendance_$timestamp.pdf';
    }
  }

  // PDF Preview
  Future<void> previewPdf(BuildContext context, {required bool isStudent}) async {
    final pdf = await _generatePdf(isStudent: isStudent);
    final fileName = _getFileName(isStudent: isStudent);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(fileName),
          ),
          body: PdfPreview(
            build: (format) => pdf.save(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
          ),
        ),
      ),
    );
  }

  // Save PDF to device
  Future<void> savePdfToDevice(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      final fileName = _getFileName(isStudent: isStudent);
      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully at $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'Could not access storage directory';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Share PDF
  Future<void> sharePdf(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      final fileName = _getFileName(isStudent: isStudent);
      
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Sharing $fileName',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Print PDF
  Future<void> printPdf(BuildContext context, {required bool isStudent}) async {
    try {
      final pdf = await _generatePdf(isStudent: isStudent);
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: _getFileName(isStudent: isStudent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AttendancePdfService {
  // Generate student attendance PDF
  static Future<pw.Document> generateStudentAttendancePdf(
      List<Map<String, dynamic>> attendances) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Student Attendance Report'),
              pw.SizedBox(height: 20),
              _buildStudentAttendanceTable(attendances),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Generate student list PDF
  static Future<pw.Document> generateStudentListPdf(
      List<Map<String, dynamic>> students) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Student List Report'),
              pw.SizedBox(height: 20),
              _buildStudentTable(students),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Generate lecturer attendance PDF
  static Future<pw.Document> generateLecturerAttendancePdf(
      List<Map<String, dynamic>> attendances) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Lecturer Attendance Report'),
              pw.SizedBox(height: 20),
              _buildLecturerAttendanceTable(attendances),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Generate lecturer list PDF
  static Future<pw.Document> generateLecturerListPdf(
      List<Map<String, dynamic>> lecturers) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Lecturer List Report'),
              pw.SizedBox(height: 20),
              _buildLecturerTable(lecturers),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Build header for PDF document
  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Attendance Management System',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated on: ${DateTime.now().toString().substring(0, 19)}',
        ),
        pw.Divider(),
      ],
    );
  }

  // Build footer for PDF document
  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 5),
        pw.Text(
          'This is an automatically generated report',
          style: pw.TextStyle(
            fontSize: 10,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '© Attendance Management System ${DateTime.now().year}',
          style: const pw.TextStyle(
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Build student attendance table
  static pw.Widget _buildStudentAttendanceTable(List<Map<String, dynamic>> attendances) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('ID', isHeader: true),
            _buildTableCell('Student Name', isHeader: true),
            _buildTableCell('Course', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...attendances.map((attendance) {
          return pw.TableRow(
            children: [
              _buildTableCell(attendance['studentId'] ?? 'N/A'),
              _buildTableCell(attendance['studentName'] ?? 'N/A'),
              _buildTableCell(attendance['courseName'] ?? 'N/A'),
              _buildTableCell(attendance['date'] ?? 'N/A'),
              _buildTableCell(attendance['status'] ?? 'N/A'),
            ],
          );
        }),
      ],
    );
  }

  // Build student list table
  static pw.Widget _buildStudentTable(List<Map<String, dynamic>> students) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('ID', isHeader: true),
            _buildTableCell('Student Name', isHeader: true),
            _buildTableCell('Email', isHeader: true),
            _buildTableCell('Department', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...students.map((student) {
          return pw.TableRow(
            children: [
              _buildTableCell(student['studentId'] ?? 'N/A'),
              _buildTableCell(student['name'] ?? 'N/A'),
              _buildTableCell(student['email'] ?? 'N/A'),
              _buildTableCell(student['department'] ?? 'N/A'),
              _buildTableCell(student['status'] ?? 'N/A'),
            ],
          );
        }),
      ],
    );
  }

  // Build lecturer attendance table
  static pw.Widget _buildLecturerAttendanceTable(List<Map<String, dynamic>> attendances) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('ID', isHeader: true),
            _buildTableCell('Lecturer Name', isHeader: true),
            _buildTableCell('Course', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...attendances.map((attendance) {
          return pw.TableRow(
            children: [
              _buildTableCell(attendance['lecturerId'] ?? 'N/A'),
              _buildTableCell(attendance['lecturerName'] ?? 'N/A'),
              _buildTableCell(attendance['courseName'] ?? 'N/A'),
              _buildTableCell(attendance['date'] ?? 'N/A'),
              _buildTableCell(attendance['status'] ?? 'N/A'),
            ],
          );
        }),
      ],
    );
  }

  // Build lecturer list table
  static pw.Widget _buildLecturerTable(List<Map<String, dynamic>> lecturers) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('ID', isHeader: true),
            _buildTableCell('Lecturer Name', isHeader: true),
            _buildTableCell('Email', isHeader: true),
            _buildTableCell('Department', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...lecturers.map((lecturer) {
          return pw.TableRow(
            children: [
              _buildTableCell(lecturer['lecturerId'] ?? 'N/A'),
              _buildTableCell(lecturer['name'] ?? 'N/A'),
              _buildTableCell(lecturer['email'] ?? 'N/A'),
              _buildTableCell(lecturer['department'] ?? 'N/A'),
              _buildTableCell(lecturer['status'] ?? 'N/A'),
            ],
          );
        }),
      ],
    );
  }

  // Helper method to build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}