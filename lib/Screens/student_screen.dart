import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendanceweb/Core/utility/pdf_export_manager.dart';

// Provider for students data from users collection
final studentsProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final currentFilter = ref.watch(studentFilterProvider);

  // Base query to get users with role "student"
  var query = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'student');
  //.orderBy('dateAdded', descending: true);

  // Apply status filter if not "All"
  if (currentFilter != 'All') {
    query = query.where('status', isEqualTo: currentFilter.toLowerCase());
  }

  return query.snapshots().map((snapshot) => snapshot.docs);
});

// Provider for filter state
final studentFilterProvider = StateProvider<String>((ref) => 'All');

// Provider for search query
final studentSearchProvider = StateProvider<String>((ref) => '');

class StudentPage extends ConsumerWidget {
  const StudentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final currentFilter = ref.watch(studentFilterProvider);
    final searchQuery = ref.watch(studentSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Export Dropdown Menu (similar to AttendanceScreen)
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Students Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddStudentDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 7, 89, 131),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter options
            Row(
              children: [
                _buildFilterChip(context, ref, 'All', currentFilter == 'All'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    context, ref, 'Approved', currentFilter == 'Approved'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    context, ref, 'Pending', currentFilter == 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    context, ref, 'Rejected', currentFilter == 'Rejected'),
              ],
            ),

            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                ref.read(studentSearchProvider.notifier).state = value;
              },
            ),

            const SizedBox(height: 16),

            // Students list
            Expanded(
              child: studentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (students) {
                  // Apply search filter
                  final filteredStudents = searchQuery.isEmpty
                      ? students
                      : students.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? '';
                          final email = data['email'] ?? '';
                          final studentId = data['studentId'] ?? '';

                          return name
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              email
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              studentId
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                        }).toList();

                  filteredStudents.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final aDate = aData['dateAdded'] as Timestamp?;
                    final bDate = bData['dateAdded'] as Timestamp?;

                    // Handle null values
                    if (aDate == null && bDate == null) return 0;
                    if (aDate == null) return 1;
                    if (bDate == null) return -1;

                    // Sort descending (newest first)
                    return bDate.compareTo(aDate);
                  });

                  if (filteredStudents.isEmpty) {
                    return const Center(
                      child: Text('No students found'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final studentData =
                          student.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                                studentData['status'] ?? 'pending'),
                            child: Text(
                              studentData['name'] != null &&
                                      studentData['name'].toString().isNotEmpty
                                  ? studentData['name']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            studentData['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('ID: ${studentData['studentId'] ?? 'N/A'}'),
                              Text('Email: ${studentData['email'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                          studentData['status'] ?? 'pending')
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  studentData['status']?.toUpperCase() ??
                                      'PENDING',
                                  style: TextStyle(
                                    color: _getStatusColor(
                                        studentData['status'] ?? 'pending'),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditStudentDialog(
                                    context, student.id, studentData);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(context, student.id);
                              } else if (value == 'approve') {
                                _updateStudentStatus(student.id, 'approved');
                              } else if (value == 'reject') {
                                _updateStudentStatus(student.id, 'rejected');
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                              const PopupMenuItem(
                                value: 'approve',
                                child: Text('Approve'),
                              ),
                              const PopupMenuItem(
                                value: 'reject',
                                child: Text('Reject'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method for handling export actions (similar to AttendanceScreen)
  void _handleExportAction(BuildContext context, WidgetRef ref, String action) async {
    // Get the current selected status
    final status = ref.read(studentFilterProvider);
    
    // Get the current search query
    final searchQuery = ref.read(studentSearchProvider);
    
    // Fetch students based on current filters
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    
    final students = studentsSnapshot.docs;
    
    // Apply status filter if not "All"
    final statusFilteredStudents = (status == 'All')
        ? students
        : students.where((doc) {
            final data = doc.data();
            return data['status']?.toLowerCase() == status.toLowerCase();
          }).toList();
    
    // Apply search filter if any
    final filteredStudents = searchQuery.isEmpty
        ? statusFilteredStudents
        : statusFilteredStudents.where((doc) {
            final data = doc.data();
            final name = data['name'] ?? '';
            final email = data['email'] ?? '';
            final studentId = data['studentId'] ?? '';

            return name.toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                email.toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                studentId.toString().toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();
    
    // Convert to a format compatible with PdfExportManager
    final studentRecords = filteredStudents.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'email': data['email'] ?? 'N/A',
        'studentId': data['studentId'] ?? 'N/A',
        'status': data['status'] ?? 'pending',
        'dateAdded': data['dateAdded'] ?? Timestamp.now(),
      };
    }).toList();
    
    // Create PDF Export Manager
    final pdfExportManager = PdfExportManager();
    pdfExportManager.setStudentRecords(studentRecords);

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

  // Preview Dialog for students (can be used separately)
  void _showPreviewDialog(BuildContext context, List<Map<String, dynamic>> students) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Student Records'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text('${student['name']}'),
                subtitle: Text('ID: ${student['studentId']}, Status: ${student['status']}'),
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

  Widget _buildFilterChip(
      BuildContext context, WidgetRef ref, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(studentFilterProvider.notifier).state = label;
        }
      },
      selectedColor: const Color.fromARGB(255, 7, 89, 131).withOpacity(0.2),
      checkmarkColor: const Color.fromARGB(255, 7, 89, 131),
      labelStyle: TextStyle(
        color:
            isSelected ? const Color.fromARGB(255, 7, 89, 131) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

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
              backgroundColor: const Color.fromARGB(255, 7, 89, 131),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(BuildContext context, String name, String email,
      String studentId, String password) async {
    try {
      // Create a new user document
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'email': email,
        'studentId': studentId,
        'password':
            password, // Note: In production, use Firebase Auth for secure authentication
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

  void _showEditStudentDialog(BuildContext context, String studentId,
      Map<String, dynamic> studentData) {
    final nameController = TextEditingController(text: studentData['name']);
    final emailController = TextEditingController(text: studentData['email']);
    final idController = TextEditingController(text: studentData['studentId']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
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
                  idController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              _updateStudent(
                context,
                studentId,
                nameController.text.trim(),
                emailController.text.trim(),
                idController.text.trim(),
              );

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 89, 131),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStudent(BuildContext context, String documentId,
      String name, String email, String studentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .update({
        'name': name,
        'email': email,
        'studentId': studentId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
            'Are you sure you want to delete this student? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteStudent(context, studentId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(BuildContext context, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateStudentStatus(String documentId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating status: $e');
    }
  }
}