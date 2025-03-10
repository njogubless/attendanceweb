// Create a new file: lib/providers/menu_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Main menu selection
final selectedIndexProvider = StateProvider<int>((ref) => 0);

// Submenu selection: 'all', 'approved', 'pending', 'rejected'
final selectedStatusProvider = StateProvider<String>((ref) => 'all');

// Course and attendance submenu
final courseAttendanceViewProvider = StateProvider<String>((ref) => 'courses');