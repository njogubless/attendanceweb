import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for students data
final studentsProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  return FirebaseFirestore.instance
      .collection('students')
      .orderBy('dateAdded', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

// Provider for filter state
final filterProvider = StateProvider<String>((ref) => 'All');

class StudentPage extends ConsumerWidget {
  const StudentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final currentFilter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                _buildFilterChip(context, ref, 'Approved', currentFilter == 'Approved'),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Pending', currentFilter == 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'Rejected', currentFilter == 'Rejected'),
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
                // Implement search functionality here
              },
            ),
            
            const SizedBox(height: 16),
            
            // Students list
            Expanded(
              child: studentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (students) {
                  // Filter students based on selected filter
                  final filteredStudents = currentFilter == 'All'
                      ? students
                      : students.where((doc) => 
                          doc['status'] == currentFilter.toLowerCase()).toList();
                  
                  if (filteredStudents.isEmpty) {
                    return const Center(
                      child: Text('No students found'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final studentData = student.data() as Map<String, dynamic>;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(studentData['status'] ?? 'pending'),
                            child: Text(
                              studentData['name'].substring(0, 1).toUpperCase(),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(studentData['status'] ?? 'pending').withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  studentData['status']?.toUpperCase() ?? 'PENDING',
                                  style: TextStyle(
                                    color: _getStatusColor(studentData['status'] ?? 'pending'),
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
                                _showEditStudentDialog(context, student.id, studentData);
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

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(filterProvider.notifier).state = label;
        }
      },
      selectedColor: const Color.fromARGB(255, 7, 89, 131).withOpacity(0.2),
      checkmarkColor: const Color.fromARGB(255, 7, 89, 131),
      labelStyle: TextStyle(
        color: isSelected ? const Color.fromARGB(255, 7, 89, 131) : Colors.black,
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
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
              if (nameController.text.isNotEmpty && 
                  emailController.text.isNotEmpty && 
                  idController.text.isNotEmpty) {
                _addStudent(
                  nameController.text,
                  emailController.text,
                  idController.text,
                );
                Navigator.pop(context);
              }
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

  void _showEditStudentDialog(BuildContext context, String studentId, Map<String, dynamic> studentData) {
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
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
              if (nameController.text.isNotEmpty && 
                  emailController.text.isNotEmpty && 
                  idController.text.isNotEmpty) {
                _updateStudent(
                  studentId,
                  nameController.text,
                  emailController.text,
                  idController.text,
                );
                Navigator.pop(context);
              }
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

  void _showDeleteConfirmation(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteStudent(studentId);
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

  void _addStudent(String name, String email, String studentId) {
    FirebaseFirestore.instance.collection('students').add({
      'name': name,
      'email': email,
      'studentId': studentId,
      'status': 'pending',
      'dateAdded': FieldValue.serverTimestamp(),
    });
  }

  void _updateStudent(String studentId, String name, String email, String id) {
    FirebaseFirestore.instance.collection('students').doc(studentId).update({
      'name': name,
      'email': email,
      'studentId': id,
    });
  }

  void _updateStudentStatus(String studentId, String status) {
    FirebaseFirestore.instance.collection('students').doc(studentId).update({
      'status': status,
    });
  }

  void _deleteStudent(String studentId) {
    FirebaseFirestore.instance.collection('students').doc(studentId).delete();
  }
}