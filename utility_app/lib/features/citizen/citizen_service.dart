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
        // No orderBy to avoid composite index requirement — sort client-side
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

  Future<Map<String, dynamic>> getCitizenStats() async {
    try {
      final snap = await _firestore
          .collection(AppCollections.reports)
          .where('reporterId', isEqualTo: _uid)
          .get();

      final reports = snap.docs;
      final resolved =
          reports.where((d) => d.data()['status'] == ReportStatus.resolved).length;
      final points = resolved * 20 + reports.length * 5;

      int rank = 1;
      try {
        final allUsersSnap = await _firestore
            .collection(AppCollections.users)
            .where('role', isEqualTo: 'citizen')
            .get();

        for (final user in allUsersSnap.docs) {
          if (user.id == _uid) continue;
          final otherSnap = await _firestore
              .collection(AppCollections.reports)
              .where('reporterId', isEqualTo: user.id)
              .get();
          if (otherSnap.docs.length > reports.length) rank++;
        }
      } catch (e) {
        print("Failed to calculate rank: $e");
      }

      return {
        'totalReports': reports.length,
        'points': points,
        'rank': rank,
      };
    } catch (e) {
      print("Citizen stats lookup error: $e");
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
            }).toList());
  }
}
