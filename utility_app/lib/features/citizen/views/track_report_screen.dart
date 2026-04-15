import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:utility_app/features/citizen/models/report_model.dart';
import 'package:utility_app/features/citizen/views/report_issue_screen.dart';

class TrackReportScreen extends StatelessWidget {
  TrackReportScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool useDemoData = false;

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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ReportModel.fromJson(data);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  String _currentUserId() => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Status helpers ────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'In Progress':
        return const Color(0xFF3B82F6);
      case 'Resolved':
        return const Color(0xFF10B981);
      default: // Pending
        return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'In Progress':
        return Icons.autorenew_rounded;
      case 'Resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  // ── Category icon ─────────────────────────────────────────────────────────

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('water')) return Icons.water_drop_rounded;
    if (c.contains('road') || c.contains('pothole')) return Icons.route_rounded;
    if (c.contains('electric') || c.contains('light')) return Icons.bolt_rounded;
    if (c.contains('waste') || c.contains('garbage')) return Icons.delete_rounded;
    if (c.contains('tree') || c.contains('park')) return Icons.park_rounded;
    return Icons.report_problem_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: const Color(0xFF057060),
            elevation: 0,
            title: const Text(
              'Report History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF057060), Color(0xFF0A9276)],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    right: -30,
                    top: -20,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    top: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Title + subtitle
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Your History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View and follow up on your submissions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<ReportModel>>(
              stream: _getUserOrDemoReports(userId),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF057060),
                        strokeWidth: 2.5,
                      ),
                    ),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _ErrorState(error: '${snapshot.error}'),
                  );
                }

                // Empty
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const _EmptyState(),
                  );
                }

                final reports = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Count pill
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF057060).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${reports.length} Report${reports.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Color(0xFF057060),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cards
                      ...reports.asMap().entries.map((entry) {
                        final r = entry.value;
                        return _ReportCard(
                          report: r,
                          statusColor: _statusColor(r.status),
                          statusIcon: _statusIcon(r.status),
                          categoryIcon: _categoryIcon(r.category),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF057060).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF057060),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          label: const Text(
            'New Report',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.statusColor,
    required this.statusIcon,
    required this.categoryIcon,
  });

  final ReportModel report;
  final Color statusColor;
  final IconData statusIcon;
  final IconData categoryIcon;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final createdAt = r.createdAt;
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colored top accent bar ──────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.4),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category icon tile
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF057060).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: const Color(0xFF057060),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title + category — Expanded so it takes available space
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              r.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge — fixed width so it never wraps or overflows
                      Container(
                        constraints: const BoxConstraints(maxWidth: 110),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                r.status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Divider ───────────────────────────────────────────
                  Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1),

                  const SizedBox(height: 12),

                  // ── Description ───────────────────────────────────────
                  Text(
                    r.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),

                  // ── Image ─────────────────────────────────────────────
                  if (r.imagePath.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: r.imagePath.startsWith('http')
                          ? Image.network(
                              r.imagePath,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : r.imagePath.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(
                                      r.imagePath.split(',').last),
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox.shrink(),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Footer ────────────────────────────────────────────
                  Row(
                    children: [
                      // Date chip
                      _FooterChip(
                        icon: Icons.calendar_today_rounded,
                        label: formattedDate,
                      ),
                      const SizedBox(width: 10),
                      // Reporter chip
                      _FooterChip(
                        icon: Icons.person_rounded,
                        label: r.reporterName,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer chip
// ─────────────────────────────────────────────────────────────────────────────

class _FooterChip extends StatelessWidget {
  const _FooterChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF057060).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 46,
                color: Color(0xFF057060),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No reports yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spotted an issue in your area?\nTap "New Report" to let us know.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 46,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}