import 'package:flutter/material.dart';
import 'package:attendanceweb/Core/utility/pdf_export_manager.dart';
import 'package:attendanceweb/Screens/attendance/attendance_model.dart';
import 'package:attendanceweb/Screens/attendance/student_attendance_tab.dart';
import 'package:attendanceweb/Screens/attendance/lecturer_attendance_tab.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PdfExportManager _pdfExportManager = PdfExportManager();
  bool _isStudentTab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      setState(() {
        _isStudentTab = true;
      });
    } else {
      setState(() {
        _isStudentTab = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onStudentDataLoaded(List<AttendanceModel> attendances) {
    _pdfExportManager.setStudentAttendances(attendances);
  }

  void _onLecturerDataLoaded(Map<String, List<AttendanceModel>> attendances) {
    _pdfExportManager.setLecturerAttendances(attendances);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        actions: [
          // PDF Export Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF options',
            onSelected: (value) {
              if (_isStudentTab && !_pdfExportManager.hasStudentData ||
                  !_isStudentTab && !_pdfExportManager.hasLecturerData) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No data available to export')),
                );
                return;
              }

              switch (value) {
                case 'preview':
                  _pdfExportManager.previewPdf(context, isStudent: _isStudentTab);
                  break;
                case 'save':
                  _pdfExportManager.savePdfToDevice(context, isStudent: _isStudentTab);
                  break;
                case 'share':
                  _pdfExportManager.sharePdf(context, isStudent: _isStudentTab);
                  break;
                case 'print':
                  _pdfExportManager.printPdf(context, isStudent: _isStudentTab);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.preview),
                    SizedBox(width: 8),
                    Text('Preview'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save to Device'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Student'),
            Tab(text: 'Lecturer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudentAttendanceTab(onDataLoaded: _onStudentDataLoaded),
          LecturerAttendanceTab(onDataLoaded: _onLecturerDataLoaded),
        ],
      ),
    );
  }
}