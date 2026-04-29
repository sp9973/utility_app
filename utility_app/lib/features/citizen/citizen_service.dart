import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'models/report_model.dart';

class CitizenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<List<ReportModel>> getMyReports() {
    return _firestore
        .collection(AppCollections.reports)
        .where('reporterId', isEqualTo: _uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return ReportModel.fromJson(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Calculates citizen stats without reading the restricted 'users' collection.
  /// It aggregates data from the 'reports' collection which is accessible.
  Future<Map<String, dynamic>> getCitizenStats() async {
    try {
      // Fetch all reports to calculate rank and stats locally
      // (This is okay as long as report volume isn't in the millions)
      final allReportsSnap = await _firestore.collection(AppCollections.reports).get();
      final allReports = allReportsSnap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return ReportModel.fromJson(data);
      }).toList();

      final myReports = allReports.where((r) => r.reporterId == _uid).toList();
      final myResolved = myReports.where((r) => r.status == ReportStatus.resolved).length;
      final myPoints = myResolved * 25 + myReports.length * 5;

      // Calculate rank locally by aggregating points for all users found in reports
      Map<String, int> userPoints = {};
      for (var r in allReports) {
        final rid = r.reporterId;
        if (rid.isEmpty) continue;
        final isResolved = r.status == ReportStatus.resolved;
        userPoints[rid] = (userPoints[rid] ?? 0) + (isResolved ? 25 : 5);
      }

      final sortedScores = userPoints.values.toList()..sort((a, b) => b.compareTo(a));
      int rank = sortedScores.indexOf(myPoints) + 1;
      if (rank <= 0) rank = 1;

      return {
        'totalReports': myReports.length,
        'points': myPoints,
        'rank': rank,
      };
    } catch (e) {
      print("Citizen stats calculation error: $e");
      return {
        'totalReports': 0,
        'points': 0,
        'rank': 1,
      };
    }
  }

  Stream<List<ReportModel>> getNearbyReports({int limit = 10}) {
    return _firestore
        .collection(AppCollections.reports)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return ReportModel.fromJson(data);
            }).toList())
        .handleError((e) {
      print("Nearby reports stream error: $e");
      return <ReportModel>[];
    });
  }
}
