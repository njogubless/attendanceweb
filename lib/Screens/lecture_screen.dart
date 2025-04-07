import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for lecturers data
final lecturersProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  return FirebaseFirestore.instance
      .collection('lecturers')
      .orderBy('dateAdded', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

class LecturePage extends ConsumerWidget {
  const LecturePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturersAsync = ref.watch(lecturersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturers'),
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
                  'Lecturers Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddLecturerDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lecturer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 7, 89, 131),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Filter options (can be expanded)
            Row(
              children: [
                _buildFilterChip('All', true),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', false),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', false),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', false),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search lecturers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lecturers data table
            Expanded(
              child: lecturersAsync.when(
                data: (lecturers) {
                  if (lecturers.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No lecturers found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first lecturer using the button above',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Card(
                    elevation: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: lecturers.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'pending';
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(data['name'] ?? 'N/A')),
                              DataCell(Text(data['email'] ?? 'N/A')),
                              DataCell(Text(data['department'] ?? 'N/A')),
                              DataCell(Text(data['phone'] ?? 'N/A')),
                              DataCell(_buildStatusBadge(status)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      _showEditLecturerDialog(context, doc);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(context, doc);
                                    },
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('Error: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        // Implement filter logic here
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color.fromARGB(255, 7, 89, 131).withOpacity(0.2),
      checkmarkColor: const Color.fromARGB(255, 7, 89, 131),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    
    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Dialog to add a new lecturer
  void _showAddLecturerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final departmentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Lecturer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addLecturerToFirestore(
                  nameController.text,
                  emailController.text,
                  phoneController.text,
                  departmentController.text,
                  context,
                );
              },
              child: const Text('Add Lecturer'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to edit a lecturer
  void _showEditLecturerDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final nameController = TextEditingController(text: data['name']);
    final emailController = TextEditingController(text: data['email']);
    final phoneController = TextEditingController(text: data['phone']);
    final departmentController = TextEditingController(text: data['department']);
    String status = data['status'] ?? 'pending';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Lecturer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.verified_user),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            status = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateLecturerInFirestore(
                      doc.id,
                      nameController.text,
                      emailController.text,
                      phoneController.text,
                      departmentController.text,
                      status,
                      context,
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Dialog to confirm deletion
  void _showDeleteConfirmationDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${data['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteLecturerFromFirestore(doc.id, context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Function to add lecturer to Firestore
  Future<void> _addLecturerToFirestore(
    String name,
    String email,
    String phone,
    String department,
    BuildContext context,
  ) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Email are required')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Add data to Firestore
      await FirebaseFirestore.instance.collection('lecturers').add({
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'status': 'pending', // Default status
        'dateAdded': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.of(context).pop();
      // Close the form dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lecturer $name added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding lecturer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to update lecturer in Firestore
  Future<void> _updateLecturerInFirestore(
    String docId,
    String name,
    String email,
    String phone,
    String department,
    String status,
    BuildContext context,
  ) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Email are required')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Update data in Firestore
      await FirebaseFirestore.instance.collection('lecturers').doc(docId).update({
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'status': status,
        'dateUpdated': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.of(context).pop();
      // Close the form dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lecturer $name updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating lecturer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to delete lecturer from Firestore
  Future<void> _deleteLecturerFromFirestore(
    String docId,
    BuildContext context,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete data from Firestore
      await FirebaseFirestore.instance.collection('lecturers').doc(docId).delete();

      // Close loading dialog
      Navigator.of(context).pop();
      // Close the confirmation dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lecturer deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting lecturer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}