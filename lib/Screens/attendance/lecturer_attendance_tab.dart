import 'package:attendanceweb/Features/Models/attendance_model.dart';
import 'package:attendanceweb/Screens/attendance/attendance_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LecturerAttendanceTab extends StatelessWidget {
  final Function(Map<String, List<AttendanceModel>>) onDataLoaded;

  const LecturerAttendanceTab({
    Key? key,
    required this.onDataLoaded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('attendances')
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No lecturer attendance records available'));
        }
        
        // Group attendances by lecturer
        Map<String, List<AttendanceModel>> lecturerAttendances = {};
        
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final attendance = AttendanceModel.fromMap(data);
          
          if (attendance.lecturerId != null) {
            if (!lecturerAttendances.containsKey(attendance.lecturerId)) {
              lecturerAttendances[attendance.lecturerId!] = [];
            }
            
            lecturerAttendances[attendance.lecturerId!]!.add(attendance);
          }
        }
        
        if (lecturerAttendances.isEmpty) {
          return const Center(child: Text('No lecturer data available'));
        }
        
        // Notify parent about loaded data for PDF generation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onDataLoaded(lecturerAttendances);
        });
        
        List<String> lecturerIds = lecturerAttendances.keys.toList();
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: lecturerIds.length,
          itemBuilder: (context, index) {
            final lecturerId = lecturerIds[index];
            final attendances = lecturerAttendances[lecturerId]!;
            
            return LecturerAttendanceCard(
              lecturerId: lecturerId,
              attendances: attendances,
            );
          },
        );
      },
    );
  }
}