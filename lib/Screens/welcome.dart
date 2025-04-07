import 'dart:async';

import 'package:attendanceweb/Services/Providers/analytics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider for current time that updates every minute
final currentTimeProvider = StreamProvider<DateTime>((ref) {
  // Create a controller to manage the stream
  final controller = StreamController<DateTime>();
  
  // Add the current time immediately
  controller.add(DateTime.now());
  
  // Set up a periodic timer to add new times
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    controller.add(DateTime.now());
  });
  
  // Make sure to cancel the timer when the provider is disposed
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  
  return controller.stream;
});

// Provider for fetching analytics data from Firestore
final analyticsProvider = StreamProvider<Map<String, int>>((ref) {
  return FirebaseFirestore.instance
      .collection('courses')
      .snapshots()
      .map((coursesSnapshot) {
        // Count total courses
        final totalCourses = coursesSnapshot.docs.length;
        
        // Get all student IDs from all courses
        final Set<String> uniqueStudentIds = {};
        final Set<String> uniqueLecturerIds = {};
        
        for (var courseDoc in coursesSnapshot.docs) {
          // Extract student IDs from enrolledStudents field
          final enrolledStudents = courseDoc.data()['enrolledStudents'] as List?;
          if (enrolledStudents != null) {
            for (var studentId in enrolledStudents) {
              uniqueStudentIds.add(studentId.toString());
            }
          }
          
          // Extract lecturer ID
          final lecturerId = courseDoc.data()['lecturerId'];
          if (lecturerId != null) {
            uniqueLecturerIds.add(lecturerId.toString());
          }
        }
        
        return {
          'students': uniqueStudentIds.length,
          'lectures': totalCourses,
          'lecturers': uniqueLecturerIds.length,
          'activeUsers': uniqueStudentIds.length + uniqueLecturerIds.length,
        };
      });
});

// Provider for courses registered
final coursesRegisteredProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('courses')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final enrolledStudents = data['enrolledStudents'] as List? ?? [];
            
            return {
              'name': data['name'] ?? 'Unnamed Course',
              'code': data['courseCode'] ?? '',
              'students': enrolledStudents.length,
              'lecturer': data['lecturerName'] ?? 'Unknown',
            };
          }).toList());
});

class WelcomeSection extends ConsumerWidget {
  final Function(int, bool) switchPage;

  const WelcomeSection({
    Key? key,
    required this.switchPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAsyncValue = ref.watch(currentTimeProvider);
    final analyticsAsyncValue = ref.watch(userAnalyticsProvider);
    final coursesAsyncValue = ref.watch(coursesDataProvider);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date
            timeAsyncValue.when(
              data: (time) => _buildHeader(time),
              loading: () => _buildHeader(DateTime.now()),
              error: (_, __) => _buildHeader(DateTime.now()),
            ),
            
            const SizedBox(height: 32),
            
            // Quick stats
            analyticsAsyncValue.when(
              data: (analytics) => _buildQuickStats(analytics),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('Error loading data: ${error.toString()}'),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Quick access buttons
            _buildQuickAccess(context),
            
            const SizedBox(height: 32),
            
            // Courses registered
            coursesAsyncValue.when(
              data: (courses) => _buildCoursesRegistered(courses),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('Error loading courses: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Total Students',
              analytics['students']?.toString() ?? '0',
              Icons.people,
              Colors.blue[100]!,
              Colors.blue[700]!,
            ),
            _buildStatCard(
              'Total Courses',
              analytics['courses']?.toString() ?? '0',
              Icons.book,
              Colors.green[100]!,
              Colors.green[700]!,
            ),
            _buildStatCard(
              'Total Lecturers',
              analytics['lecturers']?.toString() ?? '0',
              Icons.school,
              Colors.orange[100]!,
              Colors.orange[700]!,
            ),
            _buildStatCard(
              'Active Users',
              analytics['activeUsers']?.toString() ?? '0',
              Icons.person_outline,
              Colors.purple[100]!,
              Colors.purple[700]!,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(DateTime now) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(now),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 24),
            Icon(Icons.access_time, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              timeFormat.format(now),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }


Widget _buildQuickAccess(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Quick Access',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildActionButton(
            'Lectures',
            Icons.book,
            Colors.blue,
            () => switchPage(1, false),
          ),
          _buildActionButton(
            'Students',
            Icons.people,
            Colors.green,
            () => switchPage(2, false),
          ),
          _buildActionButton(
            'Add Lecture',
            Icons.add_circle_outline,
            Colors.orange,
            () {
              // Navigate to add lecture form or show dialog
              _showAddLectureDialog(context);
            },
          ),
          _buildActionButton(
            'Add Student',
            Icons.person_add,
            Colors.purple,
            () {
              // Navigate to add student form or show dialog
              _showAddStudentDialog(context);
            },
          ),
          _buildActionButton(
            'Add Lecturer',
            Icons.person_add,
            Colors.red,
            () {
              // Navigate to add lecturer form or show dialog
              _showAddLecturerDialog(context);
            },
          ),
        ],
      ),
    ],
  );
}

// Helper method for action buttons
Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
  return InkWell(
    onTap: onPressed,
    child: Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

// Dialog to add a new lecture
void _showAddLectureDialog(BuildContext context) {
  final courseNameController = TextEditingController();
  final courseCodeController = TextEditingController();
  final lecturerController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add New Lecture'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lecturerController,
              decoration: const InputDecoration(
                labelText: 'Lecturer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (courseNameController.text.isEmpty || 
                courseCodeController.text.isEmpty || 
                lecturerController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            
            _addLecture(
              context,
              courseNameController.text.trim(),
              courseCodeController.text.trim(),
              lecturerController.text.trim(),
            );
            
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// Method to add a new lecture to Firestore
Future<void> _addLecture(
  BuildContext context, 
  String courseName, 
  String courseCode, 
  String lecturer
) async {
  try {
    await FirebaseFirestore.instance.collection('courses').add({
      'name': courseName,
      'code': courseCode,
      'lecturer': lecturer,
      'dateAdded': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lecture added successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

// Dialog to add a new student
void _showAddStudentDialog(BuildContext context) {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add New Student'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isEmpty || 
                emailController.text.isEmpty || 
                idController.text.isEmpty ||
                passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            
            _addStudent(
              context,
              nameController.text.trim(),
              emailController.text.trim(),
              idController.text.trim(),
              passwordController.text.trim(),
            );
            
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
          ),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// Method to add a new student to Firestore
Future<void> _addStudent(
  BuildContext context, 
  String name, 
  String email, 
  String studentId, 
  String password
) async {
  try {
    await FirebaseFirestore.instance.collection('users').add({
      'name': name,
      'email': email,
      'studentId': studentId,
      'password': password, // In production, use Firebase Auth
      'role': 'student',
      'status': 'pending',
      'dateAdded': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student added successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

// Dialog to add a new lecturer
void _showAddLecturerDialog(BuildContext context) {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final departmentController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add New Lecturer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Lecturer ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isEmpty || 
                emailController.text.isEmpty || 
                idController.text.isEmpty ||
                passwordController.text.isEmpty ||
                departmentController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            
            _addLecturer(
              context,
              nameController.text.trim(),
              emailController.text.trim(),
              idController.text.trim(),
              departmentController.text.trim(),
              passwordController.text.trim(),
            );
            
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// Method to add a new lecturer to Firestore
Future<void> _addLecturer(
  BuildContext context, 
  String name, 
  String email, 
  String lecturerId, 
  String department,
  String password
) async {
  try {
    await FirebaseFirestore.instance.collection('users').add({
      'name': name,
      'email': email,
      'lecturerId': lecturerId,
      'department': department,
      'password': password, // In production, use Firebase Auth
      'role': 'lecturer',
      'status': 'pending',
      'dateAdded': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lecturer added successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}



  Widget _buildCoursesRegistered(List<Map<String, dynamic>> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courses Registered',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    course['code'].toString().substring(0, 1),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('${course['name']} (${course['code']})'),
                subtitle: Text('Lecturer: ${course['lecturer']}'),
                trailing: Chip(
                  label: Text(
                    '${course['students']} Students',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}