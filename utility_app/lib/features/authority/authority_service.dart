import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

class AuthorityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReportModel>> getAllReports({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppCollections.reports)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((s) => s.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return ReportModel.fromJson(data);
        }).toList());
  }

  Future<void> updateStatus(String reportId, String newStatus) async {
    await _firestore
        .collection(AppCollections.reports)
        .doc(reportId)
        .update({'status': newStatus});
  }

  Stream<Map<String, int>> getDashboardStatsStream() {
    return _firestore.collection(AppCollections.reports).snapshots().map((snap) {
      final docs = snap.docs;
      return {
        'total': docs.length,
        'pending': docs.where((d) => d.data()['status'] == ReportStatus.pending).length,
        'inProgress': docs.where((d) => d.data()['status'] == ReportStatus.inProgress).length,
        'resolved': docs.where((d) => d.data()['status'] == ReportStatus.resolved).length,
      };
    });
  }
}
