import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../citizen/models/report_model.dart';

class TrackReportScreen extends StatelessWidget {
  TrackReportScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool useDemoData = true;

  Stream<List<ReportModel>> _getUserOrDemoReports(String userId) {
    if (useDemoData) {
      return _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return ReportModel.fromJson(data);
                }).toList(),
          );
    }

    if (userId.isEmpty) return Stream.value(<ReportModel>[]);
    return _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return ReportModel.fromJson(data);
              }).toList(),
        );
  }

  String _currentUserId() => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Reports History'),
        backgroundColor: const Color(0xFF057060),
        elevation: 2,
        shadowColor: Colors.greenAccent,
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _getUserOrDemoReports(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No reports to show (demo mode)',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final reports = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              final createdAt =
                  (r.createdAt is DateTime)
                      ? r.createdAt
                      : (r.createdAt is Timestamp
                          ? (r.createdAt as Timestamp).toDate()
                          : DateTime.now());
              final formattedDate =
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}';

              // Modern Card UI
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.grey.shade300,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  r.status == "Pending"
                                      ? Colors.orange.shade100
                                      : r.status == "In Progress"
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(
                                color:
                                    r.status == "Pending"
                                        ? Colors.orange
                                        : r.status == "In Progress"
                                        ? Colors.blue
                                        : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Category
                      Text(
                        r.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        r.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Footer: Date + Reporter
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r.reporterName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
