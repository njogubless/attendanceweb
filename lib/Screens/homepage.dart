import 'package:attendanceweb/Features/Auth/auth.dart';
import 'package:attendanceweb/Screens/lecture_screen.dart';
import 'package:attendanceweb/Screens/student_screen.dart';
import 'package:attendanceweb/Screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class Homepage extends ConsumerWidget {
  const Homepage({super.key});

  Widget _showSection(int index, WidgetRef ref) {
    switch (index) {
      case 0:
        return WelcomeSection(
          switchPage: (pageIndex, _) {
            // This will be handled by the provider now
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

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Flexible(
            child: Container(
              color: const Color.fromARGB(
                  255, 7, 89, 131), // Sidebar background color
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Home
                    _buildMenuItem(
                      context: context,
                      ref: ref,
                      icon: Icons.home,
                      label: 'Home',
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

                    // Divider
                    const Divider(color: Colors.white30, height: 1),

                    // Logout
                    _buildMenuItem(
                      context: context,
                      ref: ref,
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      index: -1, // Special index for logout
                      selectedIndex: selectedIndex,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content area
          Flexible(
            flex: 5,
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
      leading: Icon(icon, color: isSelected ? Colors.blue : color),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : color,
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
}