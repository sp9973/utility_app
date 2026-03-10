import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/admin/admin_service.dart';
import 'package:utility_app/features/auth/models/user_model.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _service = AdminService();
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _service.getAdminStats();
      setState(() => _stats = stats);
    } catch (_) {}
    setState(() => _loadingStats = false);
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

  Future<void> _changeRole(UserModel user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change role for\n${user.email}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['citizen', 'authority', 'admin'].map((r) {
            return ListTile(
              title: Text(r.toUpperCase()),
              leading: Radio<String>(
                value: r,
                groupValue: user.role,
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
    if (newRole != null && newRole != user.role) {
      await _service.updateUserRole(user.uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Role updated to $newRole')));
      }
    }
  }

  Future<void> _deleteReport(ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Delete "${report.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteReport(report.id);
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Report deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _stats['totalReports'] ?? 0;
    final resolved = _stats['resolved'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final rate = (_stats['resolutionRate'] as double? ?? 0).toStringAsFixed(1);
    final users = _stats['totalUsers'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0072FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Logout from admin account?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0072FF)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (ok == true) _logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Overview"),
            Tab(icon: Icon(Icons.people), text: "Users"),
            Tab(icon: Icon(Icons.list_alt), text: "Reports"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Overview Tab ──
          RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _loadingStats
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('City Admin Dashboard',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 6),
                              const Text('System-wide overview',
                                  style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _statCard("$total", "Total Reports", Colors.purpleAccent),
                                  _statCard("$rate%", "Resolved", Colors.deepPurpleAccent),
                                  _statCard("$users", "Users", Colors.blueAccent),
                                  _statCard("$pending", "Pending", Colors.redAccent),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _infoCard("Total Reports", "$total", "All submissions", Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _infoCard("Resolved", "$resolved", "$rate% rate", Colors.green)),
                            const SizedBox(width: 10),
                            Expanded(child: _infoCard("Pending", "$pending", "Need attention", Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _infoCard("Total Users", "$users", "Registered", Colors.purple)),
                            const SizedBox(width: 10),
                            Expanded(child: _infoCard("In Progress", "${_stats['inProgress'] ?? 0}", "Being handled", Colors.teal)),
                            const SizedBox(width: 10),
                            Expanded(child: _infoCard("Resolution %", "$rate%", "Success rate", Colors.indigo)),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          // ── Users Tab ──
          StreamBuilder<List<UserModel>>(
            stream: _service.getAllUsers(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final users = snap.data!;
              if (users.isEmpty) return const Center(child: Text("No users found"));
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (ctx, i) {
                  final u = users[i];
                  final roleColors = {
                    'citizen': Colors.green,
                    'authority': Colors.blue,
                    'admin': Colors.red,
                  };
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0072FF).withOpacity(0.1),
                        child: Text(u.email[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0072FF))),
                      ),
                      title: Text(u.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text("UID: ${u.uid.substring(0, 8)}..."),
                      trailing: GestureDetector(
                        onTap: () => _changeRole(u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (roleColors[u.role] ?? Colors.grey).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: (roleColors[u.role] ?? Colors.grey).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(u.role.toUpperCase(),
                                  style: TextStyle(
                                      color: roleColors[u.role] ?? Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, size: 12,
                                  color: roleColors[u.role] ?? Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ── Reports Tab ──
          StreamBuilder<List<ReportModel>>(
            stream: _service.getAllReports(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final reports = snap.data!;
              if (reports.isEmpty) return const Center(child: Text("No reports found"));
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                itemBuilder: (ctx, i) {
                  final r = reports[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(r.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${r.category} · ${r.status}"),
                          Text(r.reporterName,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteReport(r),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      width: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }
}
