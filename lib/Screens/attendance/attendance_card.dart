import 'package:attendanceweb/Features/Models/attendance_model.dart';
import 'package:attendanceweb/Screens/attendance/formatters.dart';
import 'package:flutter/material.dart';

import 'info_row.dart';

class StudentAttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  
  const StudentAttendanceCard({
    Key? key,
    required this.attendance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPresent = attendance.status == 'approved';
    
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
                        attendance.studentName ?? 'Unknown Student',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        attendance.studentId ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  isPresent: isPresent,
                  text: isPresent ? 'Approved' : 'Pending',
                ),
              ],
            ),
            const Divider(height: 24),
            InfoRow(
              icon: Icons.school,
              label: 'Course',
              value: attendance.courseName ?? 'Not specified',
            ),
            InfoRow(
              icon: Icons.book,
              label: 'Unit',
              value: attendance.unitId ?? 'Not specified',
            ),
            InfoRow(
              icon: Icons.person,
              label: 'Lecturer',
              value: attendance.lecturerId ?? 'Not assigned',
            ),
            InfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: formatDate(attendance.attendanceDate),
            ),
            InfoRow(
              icon: Icons.location_on,
              label: 'Venue',
              value: attendance.venue ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }
}

class LecturerAttendanceCard extends StatelessWidget {
  final String lecturerId;
  final List<AttendanceModel> attendances;
  
  const LecturerAttendanceCard({
    Key? key,
    required this.lecturerId,
    required this.attendances,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firstAttendance = attendances.first;
    
    // Use the comments field to determine if lecturer had comments
    final hasComments = firstAttendance.lecturerComments != null && 
                    firstAttendance.lecturerComments!.isNotEmpty;
    
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
                        "${attendances.length} sessions",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  isBlue: true,
                  text: hasComments ? 'Has Notes' : 'No Notes',
                ),
              ],
            ),
            const Divider(height: 24),
            InfoRow(
              icon: Icons.book,
              label: 'Unit',
              value: firstAttendance.unitId ?? 'Not specified',
            ),
            InfoRow(
              icon: Icons.school,
              label: 'Course',
              value: firstAttendance.courseName ?? 'Not specified',
            ),
            InfoRow(
              icon: Icons.calendar_today,
              label: 'Last Date',
              value: formatDate(firstAttendance.attendanceDate),
            ),
            if (hasComments)
              InfoRow(
                icon: Icons.comment,
                label: 'Comments',
                value: firstAttendance.lecturerComments ?? '',
              ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final bool isPresent;
  final bool isBlue;
  final String text;

  const StatusBadge({
    Key? key,
    this.isPresent = true,
    this.isBlue = false,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isBlue) {
      color = Colors.blue;
    } else {
      color = isPresent ? Colors.green : Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}