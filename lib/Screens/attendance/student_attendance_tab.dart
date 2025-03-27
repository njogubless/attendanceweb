import 'package:attendanceweb/Features/Models/attendance_model.dart';
import 'package:attendanceweb/Screens/attendance/attendance_card.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StudentAttendanceTab extends StatelessWidget {
  final Function(List<AttendanceModel>) onDataLoaded;
  
  const StudentAttendanceTab({
    Key? key,
    required this.onDataLoaded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendances').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No student attendance records available'));
        }
        
        // Convert data to AttendanceModel objects
        final attendanceList = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AttendanceModel.fromMap(data);
        }).toList();
        
        // Notify parent about loaded data for PDF generation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onDataLoaded(attendanceList);
        });
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: attendanceList.length,
          itemBuilder: (context, index) {
            return StudentAttendanceCard(attendance: attendanceList[index]);
          },
        );
      },
    );
  }
}