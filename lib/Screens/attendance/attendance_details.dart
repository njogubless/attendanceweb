import 'package:attendanceweb/Features/Models/attendance_model.dart';
import 'package:attendanceweb/Services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final AttendanceModel attendance;
  
  const AttendanceDetailScreen({
    Key? key,
    required this.attendance,
  }) : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  late AttendanceModel _attendance;
  bool _isLoading = false;
  String _courseName = '';
  String _lecturerName = '';
  List<Map<String, dynamic>> _presentStudents = [];
  List<Map<String, dynamic>> _absentStudents = [];
  
  @override
  void initState() {
    super.initState();
    _attendance = widget.attendance;
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get course details
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(_attendance.courseId)
          .get();
      if (courseDoc.exists) {
        _courseName = courseDoc.data()?['name'] ?? 'Unknown Course';
      }
      
      // Get lecturer details
      final lecturerDoc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(_attendance.lecturerId)
          .get();
      if (lecturerDoc.exists) {
        final firstName = lecturerDoc.data()?['firstName'] ?? '';
        final lastName = lecturerDoc.data()?['lastName'] ?? '';
        _lecturerName = '$firstName $lastName';
      }
      
      // Get present students data
      _presentStudents = [];
      for (String studentId in _attendance.presentStudents) {
        try {
          final studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .get();
          if (studentDoc.exists) {
            _presentStudents.add({
              'id': studentId,
              'name': '${studentDoc.data()?['firstName'] ?? ''} ${studentDoc.data()?['lastName'] ?? ''}',
              'matricNumber': studentDoc.data()?['matricNumber'] ?? '',
              'imageUrl': studentDoc.data()?['imageUrl'] ?? '',
            });
          } else {
            _presentStudents.add({
              'id': studentId,
              'name': 'Unknown Student',
              'matricNumber': 'N/A',
              'imageUrl': '',
            });
          }
        } catch (e) {
          _presentStudents.add({
            'id': studentId,
            'name': 'Unknown Student',
            'matricNumber': 'N/A',
            'imageUrl': '',
          });
        }
      }
      
      // Get absent students data
      _absentStudents = [];
      for (String studentId in _attendance.absentStudents) {
        try {
          final studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .get();
          if (studentDoc.exists) {
            _absentStudents.add({
              'id': studentId,
              'name': '${studentDoc.data()?['firstName'] ?? ''} ${studentDoc.data()?['lastName'] ?? ''}',
              'matricNumber': studentDoc.data()?['matricNumber'] ?? '',
              'imageUrl': studentDoc.data()?['imageUrl'] ?? '',
            });
          } else {
            _absentStudents.add({
              'id': studentId,
              'name': 'Unknown Student',
              'matricNumber': 'N/A',
              'imageUrl': '',
            });
          }
        } catch (e) {
          _absentStudents.add({
            'id': studentId,
            'name': 'Unknown Student',
            'matricNumber': 'N/A',
            'imageUrl': '',
          });
        }
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateStatus(String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final updatedAttendance = _attendance.copyWith(status: newStatus);
      await AttendanceService().updateAttendance(updatedAttendance);
      
      setState(() {
        _attendance = updatedAttendance;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance status updated to $newStatus')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Implement print functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with basic info
                  Card(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _courseName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Date: ${_attendance.date}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status chip
                              Chip(
                                label: Text(
                                  _attendance.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(_attendance.status),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Lecturer: $_lecturerName',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Venue: ${_attendance.additionalData['venue'] ?? 'Not specified'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'Present',
                                  count: _presentStudents.length,
                                  color: Colors.green,
                                  icon: Icons.check_circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSummaryCard(
                                  title: 'Absent',
                                  count: _absentStudents.length,
                                  color: Colors.red,
                                  icon: Icons.cancel,
                                ),
                              ),
                              if (_presentStudents.isNotEmpty || _absentStudents.isNotEmpty)
                                const SizedBox(width: 16),
                              if (_presentStudents.isNotEmpty || _absentStudents.isNotEmpty)
                                Expanded(
                                  child: _buildSummaryCard(
                                    title: 'Attendance Rate',
                                    percent: _presentStudents.isEmpty && _absentStudents.isEmpty
                                        ? 0
                                        : (_presentStudents.length / (_presentStudents.length + _absentStudents.length) * 100).round(),
                                    color: Colors.blue,
                                    icon: Icons.pie_chart,
                                    isPercentage: true,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Present students section
                  const Text(
                    'Present Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_presentStudents.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('No students marked as present'),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _presentStudents.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student = _presentStudents[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: student['imageUrl'].isNotEmpty
                                  ? NetworkImage(student['imageUrl']) as ImageProvider
                                  : const AssetImage('assets/images/user_placeholder.png'),
                              child: student['imageUrl'].isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(student['name']),
                            subtitle: Text('ID: ${student['matricNumber']}'),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Absent students section
                  const Text(
                    'Absent Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_absentStudents.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('No students marked as absent'),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _absentStudents.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student = _absentStudents[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: student['imageUrl'].isNotEmpty
                                  ? NetworkImage(student['imageUrl']) as ImageProvider
                                  : const AssetImage('assets/images/user_placeholder.png'),
                              child: student['imageUrl'].isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(student['name']),
                            subtitle: Text('ID: ${student['matricNumber']}'),
                            trailing: const Icon(Icons.cancel, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  if (_attendance.status.toLowerCase() == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _updateStatus('approved'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _updateStatus('rejected'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    int? count,
    int? percent,
    required Color color,
    required IconData icon,
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPercentage
                ? '${percent ?? 0}%'
                : '${count ?? 0}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
}