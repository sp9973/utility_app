import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add new report
  Future<void> addReport(ReportModel report) async {
    final docRef = _firestore.collection('reports').doc();
    report.id = docRef.id;
    await docRef.set(report.toJson());
  }

  // Get all reports of a user (for Citizen dashboard)
  Stream<List<ReportModel>> getUserReports(String userId) {
    return _firestore
        .collection('reports')
        .where('reporterName', isEqualTo: userId) // or use 'userId' if you track UID
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReportModel.fromJson(doc.data())).toList());
  }

  // Get all reports (for Authority dashboard)
  Stream<List<ReportModel>> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReportModel.fromJson(doc.data())).toList());
  }

  // Update status of a report
  Future<void> updateReportStatus(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({'status': status});
  }
}
