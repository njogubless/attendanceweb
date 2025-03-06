import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
// Provider for simple analytics data (you would replace this with real data)
final analyticsProvider = Provider<Map<String, int>>((ref) {
  return {
    'students': 254,
    'lectures': 36,
    'completionRate': 78,
    'activeUsers': 142,
  };
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
    final analytics = ref.watch(analyticsProvider);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time and date
            timeAsyncValue.when(
              data: (time) => _buildHeader(time),
              loading: () => _buildHeader(DateTime.now()),
              error: (_, __) => _buildHeader(DateTime.now()),
            ),
            
            const SizedBox(height: 32),
            
            // Quick stats
            _buildQuickStats(analytics),
            
            const SizedBox(height: 32),
            
            // Quick access buttons
            _buildQuickAccess(context),
            
            const SizedBox(height: 32),
            
            // Recent activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
    String greeting;
    final hour = now.hour;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to your Admin Dashboard',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
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
              'Total Lectures',
              analytics['lectures']?.toString() ?? '0',
              Icons.book,
              Colors.green[100]!,
              Colors.green[700]!,
            ),
            _buildStatCard(
              'Completion Rate',
              '${analytics['completionRate']}%',
              Icons.trending_up,
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
        Row(
          children: [
            _buildActionButton(
              'Lectures',
              Icons.book,
              Colors.blue,
              () => switchPage(1, false),
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              'Students',
              Icons.people,
              Colors.green,
              () => switchPage(2, false),
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              'Add Lecture',
              Icons.add_circle_outline,
              Colors.orange,
              () {
                // You could navigate to a form to add a new lecture
                // For now, just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Lecture form would open here')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
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
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return _buildActivityItem(
                _demoActivities[index % _demoActivities.length],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activity['color'],
        child: Icon(
          activity['icon'],
          color: Colors.white,
        ),
      ),
      title: Text(activity['title']),
      subtitle: Text(activity['time']),
      trailing: activity['actionable']
          ? TextButton(
              onPressed: () {},
              child: const Text('View'),
            )
          : null,
    );
  }
}

// Demo data for activities
final List<Map<String, dynamic>> _demoActivities = [
  {
    'title': 'New lecture "Introduction to Flutter" added',
    'time': '10 minutes ago',
    'icon': Icons.book,
    'color': Colors.blue,
    'actionable': true,
  },
  {
    'title': 'James Smith completed "Dart Basics" course',
    'time': '1 hour ago',
    'icon': Icons.person,
    'color': Colors.green,
    'actionable': false,
  },
  {
    'title': '5 new students registered',
    'time': '3 hours ago',
    'icon': Icons.group_add,
    'color': Colors.purple,
    'actionable': true,
  },
  {
    'title': 'System maintenance scheduled',
    'time': 'Tomorrow, 2:00 AM',
    'icon': Icons.settings,
    'color': Colors.orange,
    'actionable': false,
  },
  {
    'title': 'New feedback received for "Advanced Flutter"',
    'time': 'Yesterday',
    'icon': Icons.feedback,
    'color': Colors.red,
    'actionable': true,
  },
];