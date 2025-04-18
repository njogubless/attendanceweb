import 'package:attendanceweb/Core/utility/pdf_export_manager.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for fetching lecturers
final lecturersProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final currentFilter = ref.watch(lecturerFilterProvider);
  
  // Basic query without ordering by dateAdded
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'lecturer')
      .snapshots()
      .map((snapshot) {
        // Filter by status in the app code if necessary
        if (currentFilter != 'All') {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            return data['status'] == currentFilter.toLowerCase();
          }).toList();
        }
        return snapshot.docs;
      });
});

// Provider for filter state - updated to match your actual status values
final lecturerFilterProvider = StateProvider<String>((ref) => 'All');

// Provider for search query
final lecturerSearchProvider = StateProvider<String>((ref) => '');

class LecturePage extends ConsumerWidget {
  const LecturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturersAsync = ref.watch(lecturersProvider);
    final currentFilter = ref.watch(lecturerFilterProvider);
    final searchQuery = ref.watch(lecturerSearchProvider);

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
                Row(
                  children: [
                    // New Export List button
                    ElevatedButton.icon(
                      onPressed: () {
                        lecturersAsync.whenData((lecturers) {
                          _exportLecturerList(context, lecturers);
                        });
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export List'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 89, 131),
                      ),
                    ),
                    const SizedBox(width: 10),
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
              ],
            ),
            const SizedBox(height: 24),

            // Filter options
            Row(
              children: [
                _buildFilterChip(context, ref, 'All', currentFilter == 'All'),
                const SizedBox(width: 8),
                _buildFilterChip(
                    context, ref, 'Active', currentFilter == 'Active'),
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
              onChanged: (value) {
                ref.read(lecturerSearchProvider.notifier).state = value;
              },
            ),

            const SizedBox(height: 24),

            // Lecturers data table
            Expanded(
              child: lecturersAsync.when(
                data: (lecturers) {
                  // Apply search filter
                  final filteredLecturers = searchQuery.isEmpty
                      ? lecturers
                      : lecturers.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? '';
                          final email = data['email'] ?? '';
                          final department = data['department'] ?? '';

                          return name
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              email
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              department
                                  .toString()
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase());
                        }).toList();

                  if (filteredLecturers.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: Colors.grey),
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
                        rows: filteredLecturers.map((doc) {
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
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _showEditLecturerDialog(context, doc);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(
                                          context, doc);
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

  // PDF Export functionality
  void _exportLecturerList(BuildContext context, List<DocumentSnapshot> lecturers) {
    final pdfManager = PdfExportManager();
    
    // Convert Firestore documents to the format required by the PDF service
    final lecturerRecords = lecturers.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'name': data['name'] ?? 'N/A',
        'lecturerId': doc.id,
        'email': data['email'] ?? 'N/A',
        'department': data['department'] ?? 'N/A',
        'phone': data['phone'] ?? 'N/A',
        'status': data['status'] ?? 'pending',
      };
    }).toList();
    
    // Set the data and generate the PDF
    pdfManager.setLecturerRecords(lecturerRecords);
    
    // Show the export options dialog
    _showExportOptionsDialog(context, pdfManager);
  }

  void _showExportOptionsDialog(BuildContext context, PdfExportManager pdfManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('Preview'),
              onTap: () {
                Navigator.pop(context);
                pdfManager.previewPdf(context, isStudent: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save to Device'),
              onTap: () {
                Navigator.pop(context);
                pdfManager.savePdfToDevice(context, isStudent: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                pdfManager.sharePdf(context, isStudent: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print'),
              onTap: () {
                Navigator.pop(context);
                pdfManager.printPdf(context, isStudent: false);
              },
            ),
          ],
        ),
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
          ref.read(lecturerFilterProvider.notifier).state = label;
        }
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
    final departmentController =
        TextEditingController(text: data['department']);
    String status = data['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
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
                      DropdownMenuItem(
                          value: 'active', child: Text('Active')),
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
        });
      },
    );
  }

  // Dialog to confirm deletion
  void _showDeleteConfirmationDialog(
      BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete ${data['name']}? This action cannot be undone.'),
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
  
  // Function to add lecturer to Firestore users collection
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

      // Add data to Firestore users collection
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'role': 'lecturer', // Set role to lecturer
        'status': 'active', // Default status as seen in your database
        // Removed dateAdded field as it's not present in your database
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

  // Function to update lecturer in Firestore users collection
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

      // Update data in Firestore users collection
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'status': status,
        // Removed dateUpdated field as it's not present/needed
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

  // Function to delete lecturer from Firestore users collection
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

      // Delete data from Firestore users collection
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();

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