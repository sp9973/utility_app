import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'package:utility_app/features/auth/models/user_model.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getAdminStats() async {
    final reportsSnap =
        await _firestore.collection(AppCollections.reports).get();
    final usersSnap = await _firestore.collection(AppCollections.users).get();
    final docs = reportsSnap.docs;

    final resolved =
        docs.where((d) => d.data()['status'] == ReportStatus.resolved).length;
    final pending =
        docs.where((d) => d.data()['status'] == ReportStatus.pending).length;
    final inProgress = docs
        .where((d) => d.data()['status'] == ReportStatus.inProgress)
        .length;

    double resolutionRate =
        docs.isEmpty ? 0 : (resolved / docs.length * 100);

    return {
      'totalReports': docs.length,
      'resolved': resolved,
      'pending': pending,
      'inProgress': inProgress,
      'resolutionRate': resolutionRate,
      'totalUsers': usersSnap.docs.length,
    };
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection(AppCollections.users).snapshots().map((s) =>
        s.docs.map((d) => UserModel.fromJson(d.data(), d.id)).toList());
  }

  Stream<List<ReportModel>> getAllReports() {
    return _firestore
        .collection(AppCollections.reports)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return ReportModel.fromJson(data);
            }).toList());
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore
        .collection(AppCollections.users)
        .doc(uid)
        .update({'role': newRole});
  }

  Future<void> deleteReport(String reportId) async {
    await _firestore
        .collection(AppCollections.reports)
        .doc(reportId)
        .delete();
  }

  Future<void> updateStatus(String reportId, String newStatus) async {
    await _firestore
        .collection(AppCollections.reports)
        .doc(reportId)
        .update({'status': newStatus});
  }
}
