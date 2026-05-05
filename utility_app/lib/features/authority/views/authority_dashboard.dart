import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/authority/authority_service.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';
import 'package:utility_app/core/widgets/app_drawer.dart';

class AuthorityDashboard extends StatefulWidget {
  const AuthorityDashboard({super.key});

  @override
  State<AuthorityDashboard> createState() => _AuthorityDashboardState();
}

class _AuthorityDashboardState extends State<AuthorityDashboard> {
  final AuthorityService _service = AuthorityService();
  String _selectedFilter = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Cache streams with lazy initialization to prevent LateInitializationError during hot reload
  late final Stream<Map<String, int>> _statsStream = _service.getDashboardStatsStream();
  // We use a function for this one because it depends on the filter
  Stream<List<ReportModel>> get _reportsStream => _service.getAllReports(
      statusFilter: _selectedFilter.isEmpty ? null : _selectedFilter);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _changeStatus(ReportModel report) async {
    final newStatus = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StatusPickerSheet(currentStatus: report.status),
    );
    if (newStatus != null && newStatus != report.status) {
      try {
        await _service.updateStatus(report.id, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0A4D68),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Status updated to "$newStatus"'),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              content: Text('Failed to update status: Permission Denied'),
            ),
          );
        }
      }
    }
  }

  void _showReportDetail(ReportModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReportDetailSheet(report: r, onChangeStatus: () {
        Navigator.pop(context);
        _changeStatus(r);
      }),
    );
  }

  Color _statusBg(String s) {
    switch (s) {
      case ReportStatus.pending: return Colors.orange.shade50;
      case ReportStatus.inProgress: return Colors.blue.shade50;
      case ReportStatus.resolved: return Colors.green.shade50;
      case ReportStatus.rejected: return Colors.red.shade50;
      default: return Colors.grey.shade100;
    }
  }

  Color _statusText(String s) {
    switch (s) {
      case ReportStatus.pending: return Colors.orange.shade800;
      case ReportStatus.inProgress: return Colors.blue.shade800;
      case ReportStatus.resolved: return Colors.green.shade800;
      case ReportStatus.rejected: return Colors.red.shade800;
      default: return Colors.grey.shade800;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case ReportStatus.pending: return Icons.hourglass_empty_rounded;
      case ReportStatus.inProgress: return Icons.autorenew_rounded;
      case ReportStatus.resolved: return Icons.check_circle_rounded;
      case ReportStatus.rejected: return Icons.cancel_rounded;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Authority Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0A4D68),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: const AppDrawer(role: 'authority'),
      body: Column(
        children: [
          // ─── Real-time stats banner ───────────────────────────────
          StreamBuilder<Map<String, int>>(
            stream: _statsStream,
            builder: (ctx, snap) {
              final stats = snap.data ?? {};
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A4D68), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? 'Authority',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _statCard("Total", stats['total'] ?? 0, Icons.folder_open_rounded, Colors.white),
                        const SizedBox(width: 10),
                        _statCard("Pending", stats['pending'] ?? 0, Icons.hourglass_empty_rounded, Colors.orange.shade200),
                        const SizedBox(width: 10),
                        _statCard("Active", stats['inProgress'] ?? 0, Icons.autorenew_rounded, Colors.blue.shade200),
                        const SizedBox(width: 10),
                        _statCard("Resolved", stats['resolved'] ?? 0, Icons.check_circle_rounded, Colors.green.shade200),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // ─── Search bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by title, reporter or description...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0A4D68)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          // ─── Filter chips ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip("All", ''),
                  ...ReportStatus.all.map((s) => _filterChip(s, s)),
                ],
              ),
            ),
          ),

          // ─── Reports list ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: _reportsStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                         Text("Failed to load reports",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(snap.error.toString(),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  );
                }

                var reports = snap.data ?? [];

                // Apply client-side search
                if (_searchQuery.isNotEmpty) {
                  reports = reports.where((r) =>
                    r.title.toLowerCase().contains(_searchQuery) ||
                    r.description.toLowerCase().contains(_searchQuery) ||
                    r.reporterName.toLowerCase().contains(_searchQuery) ||
                    r.category.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? "No results found" : "No reports found",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                            ? "Try a different search term"
                            : "Issues reported by citizens will appear here",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF0A4D68),
                  onRefresh: () async {}, // stream already live
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: reports.length,
                    itemBuilder: (ctx, i) {
                      final r = reports[i];
                      final date = "${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}";
                      return GestureDetector(
                        onTap: () => _showReportDetail(r),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category icon circle
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A4D68).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_categoryIcon(r.category),
                                          size: 20, color: const Color(0xFF0A4D68)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.title,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(r.category,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    // Status badge (tappable)
                                    GestureDetector(
                                      onTap: () => _changeStatus(r),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _statusBg(r.status),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(_statusIcon(r.status),
                                                size: 12, color: _statusText(r.status)),
                                            const SizedBox(width: 4),
                                            Text(r.status,
                                                style: TextStyle(
                                                    color: _statusText(r.status),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(r.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                                // Image thumbnail if present
                                if (r.imagePath.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildImage(r.imagePath, 130),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded,
                                        size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(date,
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey.shade500)),
                                    const SizedBox(width: 14),
                                    Icon(Icons.person_rounded,
                                        size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(r.reporterName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 11, color: Colors.grey.shade500)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _changeStatus(r),
                                      icon: const Icon(Icons.edit_rounded, size: 13),
                                      label: const Text("Update", style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF0A4D68),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text("$value",
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedFilter = value),
        selectedColor: const Color(0xFF0A4D68).withOpacity(0.15),
        checkmarkColor: const Color(0xFF0A4D68),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF0A4D68) : Colors.grey.shade300,
        ),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF0A4D68) : Colors.black54,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath, double height) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath,
          height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(height));
    } else if (imagePath.startsWith('data:image')) {
      try {
        return Image.memory(
            base64Decode(imagePath.split(',').last),
            height: height, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(height));
      } catch (_) {
        return _imagePlaceholder(height);
      }
    }
    return _imagePlaceholder(height);
  }

  Widget _imagePlaceholder(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade100,
      child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade300)),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'road': return Icons.route_rounded;
      case 'water': return Icons.water_drop_rounded;
      case 'electricity': return Icons.flash_on_rounded;
      case 'waste': return Icons.delete_rounded;
      default: return Icons.report_problem_rounded;
    }
  }
}

// ─── Status Picker Bottom Sheet ────────────────────────────────────────────────

class _StatusPickerSheet extends StatelessWidget {
  final String currentStatus;
  const _StatusPickerSheet({required this.currentStatus});

  Color _bg(String s) {
    switch (s) {
      case ReportStatus.pending: return Colors.orange.shade50;
      case ReportStatus.inProgress: return Colors.blue.shade50;
      case ReportStatus.resolved: return Colors.green.shade50;
      case ReportStatus.rejected: return Colors.red.shade50;
      default: return Colors.grey.shade100;
    }
  }

  Color _fg(String s) {
    switch (s) {
      case ReportStatus.pending: return Colors.orange.shade800;
      case ReportStatus.inProgress: return Colors.blue.shade800;
      case ReportStatus.resolved: return Colors.green.shade800;
      case ReportStatus.rejected: return Colors.red.shade800;
      default: return Colors.grey.shade800;
    }
  }

  IconData _icon(String s) {
    switch (s) {
      case ReportStatus.pending: return Icons.hourglass_empty_rounded;
      case ReportStatus.inProgress: return Icons.autorenew_rounded;
      case ReportStatus.resolved: return Icons.check_circle_rounded;
      case ReportStatus.rejected: return Icons.cancel_rounded;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Update Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Select a new status for this report",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 16),
          ...ReportStatus.all.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context, s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _bg(s),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentStatus == s ? _fg(s) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_icon(s), color: _fg(s), size: 22),
                    const SizedBox(width: 12),
                    Text(s, style: TextStyle(
                      color: _fg(s),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                    const Spacer(),
                    if (currentStatus == s)
                      Icon(Icons.check_rounded, color: _fg(s), size: 20),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Report Detail Bottom Sheet ─────────────────────────────────────────────

class _ReportDetailSheet extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onChangeStatus;
  const _ReportDetailSheet({required this.report, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final date = "${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}";

    Color statusBg, statusFg;
    switch (r.status) {
      case ReportStatus.pending:
        statusBg = Colors.orange.shade50; statusFg = Colors.orange.shade800; break;
      case ReportStatus.inProgress:
        statusBg = Colors.blue.shade50; statusFg = Colors.blue.shade800; break;
      case ReportStatus.resolved:
        statusBg = Colors.green.shade50; statusFg = Colors.green.shade800; break;
      case ReportStatus.rejected:
        statusBg = Colors.red.shade50; statusFg = Colors.red.shade800; break;
      default:
        statusBg = Colors.grey.shade100; statusFg = Colors.grey.shade700;
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(r.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(r.status,
                        style: TextStyle(
                            color: statusFg, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(Icons.category_rounded, "Category", r.category),
              _infoRow(Icons.person_rounded, "Reported by", r.reporterName),
              _infoRow(Icons.calendar_today_rounded, "Reported on", date),
              const Divider(height: 24),
              const Text("Description",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(r.description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
              if (r.imagePath.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Attached Image",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(r.imagePath),
                ),
              ],
              if (r.latitude != null && r.longitude != null) ...[
                const SizedBox(height: 24),
                const Text("Location",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF0A4D68), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Coords: ${r.latitude!.toStringAsFixed(4)}, ${r.longitude!.toStringAsFixed(4)}${r.address != null ? ' (${r.address})' : ''}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${r.latitude},${r.longitude}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.map_outlined, size: 14),
                        label: const Text("View Map", style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0A4D68),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onChangeStatus,
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: const Text("Update Status",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4D68),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text("$label: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath,
          width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    } else if (imagePath.startsWith('data:image')) {
      try {
        return Image.memory(base64Decode(imagePath.split(',').last),
            width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder());
      } catch (_) {
        return _placeholder();
      }
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    height: 160,
    color: Colors.grey.shade100,
    child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade300, size: 40)),
  );
}
