import 'package:attendanceweb/Features/Auth/auth.dart';
import 'package:attendanceweb/Screens/lecture_screen.dart';
import 'package:attendanceweb/Screens/student_screen.dart';
import 'package:attendanceweb/Screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

// Provider for sidebar stats 
final sidebarStatsProvider = StreamProvider<Map<String, int>>((ref) {
  return FirebaseFirestore.instance
      .collection('courses')
      .snapshots()
      .asyncMap((coursesSnapshot) async {
        // Count total courses
        final totalCourses = coursesSnapshot.docs.length;
        
        // Get all student IDs from all courses
        final Set<String> uniqueStudentIds = {};
        final Set<String> uniqueLecturerIds = {};
        int totalAttendance = 0;
        
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
          
          // Get attendance data if it exists
          try {
            final attendanceSnapshot = await FirebaseFirestore.instance
                .collection('courses')
                .doc(courseDoc.id)
                .collection('attendance')
                .get();
                
            totalAttendance += attendanceSnapshot.docs.length;
          } catch (e) {
            // Handle error or continue
          }
        }
        
        return {
          'students': uniqueStudentIds.length,
          'courses': totalCourses,
          'lecturers': uniqueLecturerIds.length,
          'attendance': totalAttendance,
        };
      });
});

class Homepage extends ConsumerWidget {
  const Homepage({super.key});

  Widget _showSection(int index, WidgetRef ref) {
    switch (index) {
      case 0:
        return WelcomeSection(
          switchPage: (pageIndex, _) {
            ref.read(selectedIndexProvider.notifier).state = pageIndex;
          },
        );
      case 1:
        return const LecturePage();
      case 2:
        return const StudentPage();
      default:
        AuthService().signOut(ref);
        return const Center();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final sidebarStatsAsync = ref.watch(sidebarStatsProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280, // Fixed width for the sidebar
            color: const Color.fromARGB(255, 7, 89, 131),
            child: Column(
              children: [
                // Logo or app name
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'Attendance System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const Divider(color: Colors.white24, height: 1),
                
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Home
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        index: 0,
                        selectedIndex: selectedIndex,
                      ),

                      // Lectures
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        icon: Icons.book,
                        label: 'Lectures',
                        index: 1,
                        selectedIndex: selectedIndex,
                      ),

                      // Students
                      _buildMenuItem(
                        context: context,
                        ref: ref,
                        icon: Icons.people,
                        label: 'Students',
                        index: 2,
                        selectedIndex: selectedIndex,
                      ),
                      
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'SYSTEM STATS',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Show stats from Firebase
                      sidebarStatsAsync.when(
                        data: (stats) => Column(
                          children: [
                            _buildStatItem(
                              icon: Icons.people,
                              label: 'Students',
                              value: '${stats['students'] ?? 0}',
                            ),
                            _buildStatItem(
                              icon: Icons.school,
                              label: 'Lecturers',
                              value: '${stats['lecturers'] ?? 0}',
                            ),
                            _buildStatItem(
                              icon: Icons.book,
                              label: 'Courses',
                              value: '${stats['courses'] ?? 0}',
                            ),
                            _buildStatItem(
                              icon: Icons.event_available,
                              label: 'Attendance Records',
                              value: '${stats['attendance'] ?? 0}',
                            ),
                          ],
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Failed to load stats',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white24, height: 1),
                
                // Logout
                _buildMenuItem(
                  context: context,
                  ref: ref,
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  index: -1, // Special index for logout
                  selectedIndex: selectedIndex,
                  color: Colors.redAccent,
                ),
                
                // User info at bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: AuthService().getCurrentUserEmail(),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'Admin User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            const Text(
                              'Administrator',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: _showSection(selectedIndex, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required int index,
    required int selectedIndex,
    Color color = Colors.white,
  }) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : color),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.white10 : Colors.transparent,
      onTap: () {
        if (index >= 0) {
          // Update selected index
          ref.read(selectedIndexProvider.notifier).state = index;
        } else {
          // Logout
          AuthService().signOut(ref);
        }
      },
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Add this to the AuthService class
extension AuthServiceExtension on AuthService {
  Future<String> getCurrentUserEmail() async {
    final user = currentUser;
    return user?.email ?? 'Admin User';
  }
}