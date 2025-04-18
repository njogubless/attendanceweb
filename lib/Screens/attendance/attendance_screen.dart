import 'package:attendanceweb/Core/utility/pdf_export_manager.dart';
import 'package:attendanceweb/Features/Models/attendance_model.dart';
import 'package:attendanceweb/Services/attendance_service.dart';
import 'package:attendanceweb/Services/Providers/status_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Status filter provider
final attendanceStatusFilterProvider = StateProvider<String>((ref) => 'all');

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(selectedStatusProvider);
    final attendanceService = AttendanceService();

    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Records'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            onTap: (index) {
              switch (index) {
                case 0:
                  ref.read(selectedStatusProvider.notifier).state = 'all';
                  break;
                case 1:
                  ref.read(selectedStatusProvider.notifier).state = 'approved';
                  break;
                case 2:
                  ref.read(selectedStatusProvider.notifier).state = 'pending';
                  break;
                case 3:
                  ref.read(selectedStatusProvider.notifier).state = 'rejected';
                  break;
              }
            },
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Approved'),
              Tab(text: 'Pending'),
              Tab(text: 'Rejected'),
            ],
            labelColor: const Color(0xFF075983),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF075983),
          ),
          actions: [
            // Export Dropdown Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                _handleExportAction(context, ref, value);
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      Icon(Icons.preview, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Preview'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Save to Device'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Export PDF'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAttendanceList(attendanceService, 'all'),
            _buildAttendanceList(attendanceService, 'approved'),
            _buildAttendanceList(attendanceService, 'pending'),
            _buildAttendanceList(attendanceService, 'rejected'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF075983),
          child: const Icon(Icons.add),
          onPressed: () {
            // Navigate to add attendance screen
          },
        ),
      ),
    );
  }

  void _handleExportAction(
      BuildContext context, WidgetRef ref, String action) async {
    // Get the current selected status
    final status = ref.read(selectedStatusProvider);

    // Fetch attendance records based on current status
    final attendanceService = AttendanceService();
    final records = await attendanceService.getAllAttendance().first;

    // Filter records based on current status
    final filteredRecords = records.where((record) {
      if (status == 'all') return true;
      return record.status.toLowerCase() == status.toLowerCase();
    }).toList();

    // Create PDF Export Manager
    final pdfExportManager = PdfExportManager();
    pdfExportManager.setStudentAttendances(filteredRecords.cast<Map<String, dynamic>>());

    // Perform selected action
    switch (action) {
      case 'preview':
        pdfExportManager.previewPdf(context, isStudent: true);
        break;
      case 'save':
        pdfExportManager.savePdfToDevice(context, isStudent: true);
        break;
      case 'share':
        pdfExportManager.sharePdf(context, isStudent: true);
        break;
      case 'pdf':
        pdfExportManager.printPdf(context, isStudent: true);
        break;
    }
  }

  // Dialog to show preview of records
  void _showPreviewDialog(BuildContext context, List<AttendanceModel> records) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Attendance Records'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                title: Text('Student ID: ${record.presentStudents.first}'),
                subtitle: Text(
                    'Course: ${record.courseId}, Status: ${record.status}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
      AttendanceService attendanceService, String status) {
    return StreamBuilder<List<AttendanceModel>>(
      stream: attendanceService.getAllAttendance(),
      builder: (context, snapshot) {
        debugPrint('connections State: ${snapshot.connectionState}');
        debugPrint('Has Data: ${snapshot.hasData}');
        debugPrint('Error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No attendance records found'));
        }

        // Filter records by status
        final attendanceList = snapshot.data!.where((record) {
          if (status == 'all') {
            return true;
          }
          return record.status.toLowerCase() == status.toLowerCase();
        }).toList();

        if (attendanceList.isEmpty) {
          return Center(
            child: Text('No $status attendance records found'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: attendanceList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final attendance = attendanceList[index];
            return AttendanceCard(attendance: attendance);
          },
        );
      },
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;

  const AttendanceCard({
    Key? key,
    required this.attendance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(attendance.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getStatusIcon(attendance.status),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Main information with student name instead of ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: attendance.presentStudents.isNotEmpty
                            ? _getUserNameById(attendance.presentStudents.first)
                            : Future.value('N/A'),
                        builder: (context, snapshot) {
                          final studentId = attendance.presentStudents.isNotEmpty
                              ? attendance.presentStudents.first
                              : 'N/A';
                          return Text(
                            'Student: ${snapshot.data ?? studentId}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${attendance.attendanceDate}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status text
                Chip(
                  label: Text(
                    attendance.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(attendance.status),
                ),
              ],
            ),

            const Divider(height: 24),

            // Course details
            Row(
              children: [
                const Icon(Icons.school, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: attendance.courseName != null 
                        ? Future.value(attendance.courseName)
                        : _getCourseNameById(attendance.unitId ?? attendance.courseId),
                    builder: (context, snapshot) {
                      return Text(
                        'Course: ${snapshot.data ?? 'Not checked'}',
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lecturer details - updated to use the users collection
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _getUserNameById(attendance.lecturerId ?? attendance.lecturerName ?? ''),
                    initialData: attendance.lecturerName,
                    builder: (context, snapshot) {
                      return Text(
                        'Lecturer: ${snapshot.data ?? 'Not specified'}',
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Venue details
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Venue: ${attendance.venue ?? 'Not specified'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (attendance.status.toLowerCase() == 'pending')
                  TextButton.icon(
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Approve',
                        style: TextStyle(color: Colors.green)),
                    onPressed: () {
                      _updateAttendanceStatus(attendance, 'approved');
                    },
                  ),
                if (attendance.status.toLowerCase() == 'pending')
                  const SizedBox(width: 8),
                if (attendance.status.toLowerCase() == 'pending')
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _updateAttendanceStatus(attendance, 'rejected');
                    },
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.grey)),
                  onPressed: () {
                    _deleteAttendance(attendance);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.info;
    }
  }

  // New method to get user name from users collection
  Future<String> _getUserNameById(String userId) async {
    if (userId.isEmpty) return 'Not specified';
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        // Get name directly from the name field as shown in your screenshot
        final name = doc.data()?['name'];
        if (name != null && name.isNotEmpty) {
          return name;
        }
        
        // Fallback to other possible name fields if needed
        final firstName = doc.data()?['firstName'] ?? '';
        final lastName = doc.data()?['lastName'] ?? '';
        
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          return '$firstName $lastName'.trim();
        }
        
        return userId;
      }
      return userId;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return userId;
    }
  }

  Future<String> _getCourseNameById(String courseId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      // Check if 'coursename' or 'name' field exists
      if (doc.exists) {
        return doc.data()?['coursename'] ?? doc.data()?['name'] ?? courseId;
      }
      return courseId;
    } catch (e) {
      debugPrint('Error fetching course: $e');
      return courseId;
    }
  }

  // Keep this method for backward compatibility or if lecturer info is still stored in lecturers collection
  Future<String> _getLecturerNameById(String lecturerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(lecturerId)
          .get();

      if (doc.exists) {
        // Try different field names that might contain the lecturer name
        final firstName = doc.data()?['firstName'] ?? '';
        final lastName = doc.data()?['lastName'] ?? '';

        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          return '$firstName $lastName'.trim();
        }

        // If no first/last name fields, try a direct 'name' field
        return doc.data()?['name'] ?? lecturerId;
      }
      return lecturerId;
    } catch (e) {
      debugPrint('Error fetching lecturer: $e');
      return lecturerId;
    }
  }

  void _updateAttendanceStatus(AttendanceModel attendance, String newStatus) {
    final updatedAttendance = attendance.copyWith(status: newStatus);
    AttendanceService().updateAttendance(updatedAttendance);
  }

  void _deleteAttendance(AttendanceModel attendance) {
    // Show confirmation dialog before deleting
    AttendanceService().deleteAttendance(attendance.courseId, attendance.id);
  }
}