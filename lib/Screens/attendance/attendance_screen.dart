import 'package:attendanceweb/Core/utility/pdf_export_manager.dart';
import 'package:flutter/material.dart';
import 'student_attendance_tab.dart';
import 'lecturer_attendance_tab.dart';


class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PdfExportManager _pdfExportManager = PdfExportManager();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    // Force rebuild when tab changes to update export button functionality
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StudentAttendanceTab(onDataLoaded: _pdfExportManager.setStudentAttendances),
                LecturerAttendanceTab(onDataLoaded: _pdfExportManager.setLecturerAttendances),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Attendance Records',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildExportButton(),
      ],
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        tabs: const [
          Tab(text: 'Student'),
          Tab(text: 'Lecturer'),
        ],
      ),
    );
  }
  
  Widget _buildExportButton() {
    bool isDataAvailable = _tabController.index == 0 
        ? _pdfExportManager.hasStudentData 
        : _pdfExportManager.hasLecturerData;
        
    return PopupMenuButton<String>(
      enabled: isDataAvailable,
      icon: Icon(
        Icons.more_vert,
        color: isDataAvailable ? Colors.blue : Colors.grey,
      ),
      tooltip: isDataAvailable ? 'Export options' : 'No data available',
      onSelected: (value) async {
        if (value == 'preview') {
          await _pdfExportManager.previewPdf(
            context, 
            isStudent: _tabController.index == 0
          );
        } else if (value == 'save') {
          await _pdfExportManager.savePdfToDevice(
            context, 
            isStudent: _tabController.index == 0
          );
        } else if (value == 'share') {
          await _pdfExportManager.sharePdf(
            context, 
            isStudent: _tabController.index == 0
          );
        } else if (value == 'print') {
          await _pdfExportManager.printPdf(
            context, 
            isStudent: _tabController.index == 0
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'preview',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Preview'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'save',
          child: ListTile(
            leading: Icon(Icons.save),
            title: Text('Save to device'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text('Share'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'print',
          child: ListTile(
            leading: Icon(Icons.print),
            title: Text('Print'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}