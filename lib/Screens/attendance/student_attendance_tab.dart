import 'package:attendanceweb/Screens/attendance/attendance_card.dart';
import 'package:attendanceweb/Screens/attendance/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StudentAttendanceTab extends StatelessWidget {
  const StudentAttendanceTab({Key? key}) : super(key: key);

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
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final attendanceData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final attendance = AttendanceModel.fromMap(attendanceData);
            
            return StudentAttendanceCard(attendance: attendance);
          },
        );
      },
    );
  }
}