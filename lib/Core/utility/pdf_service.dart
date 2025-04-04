import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// Utility class for PDF generation and printing
class AttendancePdfService {
  // Generate PDF for student attendance
  static Future<pw.Document> generateStudentAttendancePdf(List<Map<String, dynamic>> attendances) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Center(
          child: pw.Text('Student Attendance Report', 
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Student', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Course', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Data rows
              ...attendances.map((attendance) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(attendance['studentName'] ?? 'Unknown'),
                        pw.Text(attendance['studentId'] ?? '',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (attendance['studentEmail'] != null && attendance['studentEmail'].toString().isNotEmpty)
                          pw.Text(attendance['studentEmail'].toString(),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        if (attendance['registrationNumber'] != null && attendance['registrationNumber'].toString().isNotEmpty)
                          pw.Text('Reg: ${attendance['registrationNumber']}',
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(attendance['courseName'] ?? 'Not specified'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(attendance['unitId'] ?? 'Not specified'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_formatPdfDate(attendance['attendanceDate'])),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      attendance['status'] == 'approved' ? 'Approved' : 'Pending',
                      style: pw.TextStyle(
                        color: attendance['status'] == 'approved' ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 20),
          // Add comments section if any comments exist
          ...attendances
              .where((attendance) => 
                  (attendance['studentComments'] != null && attendance['studentComments'].toString().isNotEmpty) || 
                  (attendance['lecturerComments'] != null && attendance['lecturerComments'].toString().isNotEmpty))
              .map((attendance) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Comments for ${attendance['studentName'] ?? 'Unknown'}:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        if (attendance['lecturerComments'] != null && attendance['lecturerComments'].toString().isNotEmpty)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Lecturer: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.Text(attendance['lecturerComments'].toString(), style: const pw.TextStyle(fontSize: 10)),
                              pw.SizedBox(height: 4),
                            ],
                          ),
                        if (attendance['studentComments'] != null && attendance['studentComments'].toString().isNotEmpty)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Student: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.Text(attendance['studentComments'].toString(), style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                      ],
                    ),
                  )).toList(),
          pw.SizedBox(height: 20),
          pw.Text('Generated on: ${DateTime.now().toString().split('.').first}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
    
    return pdf;
  }

  // Generate PDF for lecturer attendance
  static Future<pw.Document> generateLecturerAttendancePdf(Map<String, List<Map<String, dynamic>>> lecturerAttendances) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Center(
          child: pw.Text('Lecturer Attendance Report', 
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          ...lecturerAttendances.entries.map((entry) {
            final lecturerId = entry.key;
            final attendances = entry.value;
            
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.blue100,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    children: [
                      pw.Text('Lecturer ID: $lecturerId', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
                      ),
                      pw.Spacer(),
                      pw.Text('${attendances.length} sessions'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Course', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Venue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Data rows
                    ...attendances.map((attendance) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(attendance['courseName'] ?? 'Not specified'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(attendance['unitId'] ?? 'Not specified'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_formatPdfDate(attendance['attendanceDate'])),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(attendance['venue'] ?? 'Not specified'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            attendance['isSubmitted'] == true ? 'Submitted' : 'Pending',
                            style: pw.TextStyle(
                              color: attendance['isSubmitted'] == true ? PdfColors.green : PdfColors.orange,
                            ),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 16),
                if (attendances.isNotEmpty && 
                    attendances.first['lecturerComments'] != null && 
                    attendances.first['lecturerComments'].toString().isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Comments:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(attendances.first['lecturerComments']),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 24),
              ],
            );
          }).toList(),
          pw.Text('Generated on: ${DateTime.now().toString().split('.').first}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
    
    return pdf;
  }

  // Save PDF to the device's documents directory
  static Future<File> savePdf(String fileName, pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Helper method to format date for PDF
  static String _formatPdfDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } else if (timestamp is DateTime) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (timestamp is String) {
      return timestamp;
    }
    return 'Unknown';
  }

  // Share the generated PDF file
  static Future<void> sharePdf(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Sharing attendance report');
  }

  // Print the PDF
  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}