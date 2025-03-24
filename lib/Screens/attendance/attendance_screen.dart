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
      length: 4,  // Number of tabs
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
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                // Implement print functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // Implement export functionality
              },
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

  Widget _buildAttendanceList(AttendanceService attendanceService, String status) {
    return StreamBuilder<List<AttendanceModel>>(
      stream: attendanceService.getAllAttendance(),
      builder: (context, snapshot) {
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
                
                // Main information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student ID: ${attendance.presentStudents.first}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${attendance.date}',
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
                    future: _getCourseNameById(attendance.courseId),
                    builder: (context, snapshot) {
                      return Text(
                        'Course: ${snapshot.data ?? attendance.courseId}',
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Lecturer details
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _getLecturerNameById(attendance.lecturerId),
                    builder: (context, snapshot) {
                      return Text(
                        'Lecturer: ${snapshot.data ?? attendance.lecturerId}',
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
                  'Venue: ${attendance.additionalData['venue'] ?? 'Not specified'}',
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
                    label: const Text('Approve', style: TextStyle(color: Colors.green)),
                    onPressed: () {
                      _updateAttendanceStatus(attendance, 'approved');
                    },
                  ),
                if (attendance.status.toLowerCase() == 'pending')
                  const SizedBox(width: 8),
                if (attendance.status.toLowerCase() == 'pending')
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _updateAttendanceStatus(attendance, 'rejected');
                    },
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  label: const Text('Delete', style: TextStyle(color: Colors.grey)),
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
  
  Future<String> _getCourseNameById(String courseId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();
      return doc.data()?['name'] ?? courseId;
    } catch (e) {
      return courseId;
    }
  }
  
  Future<String> _getLecturerNameById(String lecturerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(lecturerId)
          .get();
      return '${doc.data()?['firstName'] ?? ''} ${doc.data()?['lastName'] ?? ''}';
    } catch (e) {
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