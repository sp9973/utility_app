import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../citizen/models/report_model.dart';

class AuthorityDashboard extends StatelessWidget {
  AuthorityDashboard({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReportModel>> _getAllReports() {
    return _firestore
        .collection('reports')
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

  Color _statusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange.shade100;
      case "In Progress":
        return Colors.blue.shade100;
      case "Resolved":
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange.shade800;
      case "In Progress":
        return Colors.blue.shade800;
      case "Resolved":
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Authority Dashboard"),
        backgroundColor: const Color(0xFF0A4D68),
        elevation: 3,
        shadowColor: Colors.black54,
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _getAllReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final reports = snapshot.data!;
          if (reports.isEmpty)
            return const Center(child: Text("No reports found"));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final formattedDate =
                  "${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}";

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.grey.shade300,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              report.title,
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
                              color: _statusColor(report.status),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              report.status,
                              style: TextStyle(
                                color: _statusTextColor(report.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Category Chip
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(
                            report.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        report.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Footer: date and reporter
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
                            report.reporterName,
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
