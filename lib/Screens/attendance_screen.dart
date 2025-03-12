import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
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
          const Text(
            'Attendance Records',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                StudentAttendanceList(),
                LecturerAttendanceList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudentAttendanceList extends StatelessWidget {
  const StudentAttendanceList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendances').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No student attendance records available'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final attendanceData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final bool isPresent = attendanceData['status'] == 'approved';
            
            // Get associated student data
            String studentId = attendanceData['studentId'] ?? '';
            String studentName = attendanceData['studentName'] ?? 'Unknown Student';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isPresent ? Colors.green[100] : Colors.red[100],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isPresent ? Icons.check : Icons.close,
                              color: isPresent ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                studentId,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPresent ? 'Approved' : 'Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.school,
                      'Course',
                      attendanceData['courseName'] ?? 'Not specified'
                    ),
                    _buildInfoRow(
                      Icons.book,
                      'Unit',
                      attendanceData['unitId'] ?? 'Not specified'
                    ),
                    _buildInfoRow(
                      Icons.person,
                      'Lecturer',
                      attendanceData['lecturerId'] ?? 'Not assigned'
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      _formatDate(attendanceData['attendanceDate'])
                    ),
                    _buildInfoRow(
                      Icons.location_on,
                      'Venue',
                      attendanceData['venue'] ?? 'Not specified'
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } else if (timestamp is String) {
      return timestamp;
    }
    return 'Unknown';
  }
}

class LecturerAttendanceList extends StatelessWidget {
  const LecturerAttendanceList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('attendances')
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No lecturer attendance records available'));
        }
        
        // Group attendances by lecturer
        Map<String, List<DocumentSnapshot>> lecturerAttendances = {};
        
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lecturerId = data['lecturerId'] as String?;
          
          if (lecturerId != null) {
            if (!lecturerAttendances.containsKey(lecturerId)) {
              lecturerAttendances[lecturerId] = [];
            }
            
            lecturerAttendances[lecturerId]!.add(doc);
          }
        }
        
        if (lecturerAttendances.isEmpty) {
          return const Center(child: Text('No lecturer data available'));
        }
        
        List<String> lecturerIds = lecturerAttendances.keys.toList();
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: lecturerIds.length,
          itemBuilder: (context, index) {
            final lecturerId = lecturerIds[index];
            final firstAttendanceData = lecturerAttendances[lecturerId]!.first.data() as Map<String, dynamic>;
            
            // Use the comments field to determine if lecturer had comments
            final hasComments = firstAttendanceData['lecturerComments'] != null && 
                            firstAttendanceData['lecturerComments'].toString().isNotEmpty;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lecturer ID: $lecturerId",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "${lecturerAttendances[lecturerId]!.length} sessions",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasComments ? 'Has Notes' : 'No Notes',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.book,
                      'Unit',
                      firstAttendanceData['unitId'] ?? 'Not specified'
                    ),
                    _buildInfoRow(
                      Icons.school,
                      'Course',
                      firstAttendanceData['courseName'] ?? 'Not specified'
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Last Date',
                      _formatDate(firstAttendanceData['attendanceDate'])
                    ),
                    if (hasComments)
                      _buildInfoRow(
                        Icons.comment,
                        'Comments',
                        firstAttendanceData['lecturerComments'] ?? ''
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } else if (timestamp is String) {
      return timestamp;
    }
    return 'Unknown';
  }
}