import 'package:attendanceweb/Features/Models/unit_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UnitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all units created by a lecturer
  Stream<List<UnitModel>> getLecturerUnits(String lecturerId) {
    return _firestore
        .collection('units')
        .where('lecturerId', isEqualTo: lecturerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get all approved units (for students to view and register)
  Stream<List<UnitModel>> getApprovedUnits() {
    return _firestore
        .collection('units')
        .where('status', isEqualTo: UnitStatus.approved.toString().split('.').last)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Create a new unit (initially with pending status)
  Future<String> createUnit(UnitModel unit) async {
    try {
      final docRef = await _firestore.collection('units').add(unit.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update unit details
  Future<void> updateUnit(UnitModel unit) async {
    try {
      await _firestore.collection('units').doc(unit.id).update(unit.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Toggle attendance activation status
  Future<void> toggleAttendanceStatus(String unitId, bool isActive) async {
    try {
      await _firestore.collection('units').doc(unitId).update({
        'isAttendanceActive': isActive,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Admin approves a unit
  Future<void> approveUnit(String unitId, {String comments = ''}) async {
    try {
      await _firestore.collection('units').doc(unitId).update({
        'status': UnitStatus.approved.toString().split('.').last,
        'adminComments': comments,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Admin rejects a unit
  Future<void> rejectUnit(String unitId, {required String comments}) async {
    try {
      await _firestore.collection('units').doc(unitId).update({
        'status': UnitStatus.rejected.toString().split('.').last,
        'adminComments': comments,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete a unit
  Future<void> deleteUnit(String unitId) async {
    try {
      await _firestore.collection('units').doc(unitId).delete();
    } catch (e) {
      rethrow;
    }
  }
}