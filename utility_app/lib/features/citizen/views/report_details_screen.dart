import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;

  const ReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppCollections.reports)
          .doc(report.id)
          .snapshots(),
      builder: (context, snapshot) {
        // Fallback to initial report data if stream hasn't emitted or failed
        final r = snapshot.hasData && snapshot.data!.exists
            ? ReportModel.fromJson({
                ...snapshot.data!.data() as Map<String, dynamic>,
                'id': snapshot.data!.id,
              })
            : report;

        final statusColor = r.status == 'Resolved'
            ? const Color(0xFF10B981)
            : r.status == 'In Progress'
                ? const Color(0xFF3B82F6)
                : const Color(0xFFF59E0B);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: r.imagePath.isNotEmpty
                      ? _buildHeaderImage(r)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF057060), Color(0xFF00BFA5)],
                            ),
                          ),
                        ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Text(
                            _formatDate(r.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        r.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Category: ${r.category}",
                        style: const TextStyle(color: Color(0xFF057060), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.description,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Resolution Progress",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildTimeline(r),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderImage(ReportModel r) {
    if (r.imagePath.startsWith('http')) {
      return Image.network(r.imagePath, fit: BoxFit.cover);
    } else if (r.imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(r.imagePath.split(',').last),
        fit: BoxFit.cover,
      );
    }
    return Container();
  }

  Widget _buildTimeline(ReportModel r) {
    final steps = [
      {'title': 'Issue Reported', 'subtitle': 'Report received by authorities'},
      {'title': 'Acknowledged', 'subtitle': 'Staff assigned to investigate'},
      {'title': 'In Progress', 'subtitle': 'Work is currently underway'},
      {'title': 'Resolved', 'subtitle': 'Issue resolved and verified'},
    ];

    int currentStep = 0;
    if (r.status == 'Pending') currentStep = 1;
    if (r.status == 'In Progress') currentStep = 3; // Jump to work in progress
    if (r.status == 'Resolved') currentStep = 4;

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index < currentStep;
        final isLast = index == steps.length - 1;
        final stepColor = isActive ? const Color(0xFF057060) : Colors.grey.shade300;

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF057060) : Colors.white,
                      border: Border.all(color: stepColor, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: isActive
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: stepColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index]['subtitle']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.grey.shade700 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
