import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/admin/admin_service.dart';
import 'package:utility_app/features/auth/models/user_model.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';
import 'package:utility_app/core/constants/app_constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _service = AdminService();

  // Premium Color Palette
  static const Color primaryBlue = Color(0xFF0061FF);
  static const Color secondaryBlue = Color(0xFF60EFFF);
  static const Color accentPurple = Color(0xFF6A11CB);
  static const Color bgLight = Color(0xFFF0F2F5);
  static const Color cardShadow = Color(0x1A000000);

  // Lazy initialized streams
  late final Stream<Map<String, dynamic>> _statsStream = _service.getAdminStatsStream();
  late final Stream<List<UserModel>> _usersStream = _service.getAllUsers();
  late final Stream<List<ReportModel>> _reportsStream = _service.getAllReports();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _changeRole(UserModel user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.security_rounded, size: 40, color: primaryBlue),
            const SizedBox(height: 12),
            Text("Update Permissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['citizen', 'authority', 'admin'].map((r) {
            return RadioListTile<String>(
              title: Text(r.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: r,
              groupValue: user.role,
              activeColor: primaryBlue,
              onChanged: (v) => Navigator.pop(ctx, v),
            );
          }).toList(),
        ),
      ),
    );
    if (newRole != null && newRole != user.role) {
      try {
        await _service.updateUserRole(user.uid, newRole);
        _showSuccess('Role updated to ${newRole.toUpperCase()}');
      } catch (e) {
        _showError('Permission Denied: Only server admins can change roles');
      }
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('ADMIN DASHBOARD', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2,color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentPurple, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                onPressed: _logout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: primaryBlue,
                indicatorWeight: 4,
                labelColor: primaryBlue,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "ANALYTICS"),
                  Tab(text: "SYSTEM USERS"),
                  Tab(text: "CITY REPORTS"),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAnalyticsTab(),
            _buildUsersTab(),
            _buildReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return _AdminTabWrapper(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _statsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final stats = snapshot.data!;
          final total = stats['totalReports'] ?? 0;
          final resolved = stats['resolved'] ?? 0;
          final rateValue = stats['resolutionRate'] ?? 0.0;
          final rate = (rateValue as num).toDouble().toStringAsFixed(1);
          final hasUserPermission = stats['hasUserPermission'] ?? true;
          final hasReportPermission = stats['hasReportPermission'] ?? true;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!hasReportPermission) _buildPermissionBanner("Reports Access Locked", "Your account cannot list city reports in Firestore.", Colors.red),
              
              _buildSectionHeader("Key Performance"),
              const SizedBox(height: 12),
              Row(
                children: [
                  _mainStatCard("Reports", "$total", Icons.assignment_rounded, primaryBlue),
                  const SizedBox(width: 16),
                  _mainStatCard("Success", "$rate%", Icons.trending_up_rounded, Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildSectionHeader("System Status"),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _statusCard("Resolved", "$resolved", Icons.check_circle_outline, Colors.teal),
                  _statusCard("Pending", "${stats['pending'] ?? 0}", Icons.hourglass_empty, Colors.orange),
                  _statusCard("Active", "${stats['inProgress'] ?? 0}", Icons.sync, Colors.blue),
                  _statusCard("Users", "${stats['totalUsers'] ?? 0}", Icons.people_outline, Colors.purple),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader("Quick Actions"),
              const SizedBox(height: 12),
              _quickActionTile("Broadcast Update", "Send notification to all citizens", Icons.campaign_rounded, primaryBlue),
              _quickActionTile("System Logs", "View detailed cloud audit logs", Icons.terminal_rounded, Colors.black87),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    return _AdminTabWrapper(
      child: StreamBuilder<List<UserModel>>(
        stream: _usersStream,
        builder: (ctx, snap) {
          if (snap.hasError) return _buildErrorState("Permission Denied: User list is private");
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final users = snap.data!;
          if (users.isEmpty) return _buildEmptyState(Icons.people_outline, "No Users Found");

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final u = users[i];
              return _userListTile(u);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportsTab() {
    return _AdminTabWrapper(
      child: StreamBuilder<List<ReportModel>>(
        stream: _reportsStream,
        builder: (ctx, snap) {
          if (snap.hasError) return _buildErrorState("Permission Denied: Reports are restricted");
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final reports = snap.data!;
          if (reports.isEmpty) return _buildEmptyState(Icons.assignment_outlined, "No Reports Found");

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final r = reports[i];
              return _reportListTile(r);
            },
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), 
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade300, letterSpacing: 1.5));
  }

  Widget _mainStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userListTile(UserModel u) {
    final roleColor = u.role == 'admin' ? Colors.red : (u.role == 'authority' ? primaryBlue : Colors.green);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.1),
          child: Text(u.email[0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(u.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(u.uid.substring(0, 8), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        trailing: ActionChip(
          label: Text(u.role.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
          backgroundColor: roleColor,
          padding: EdgeInsets.zero,
          onPressed: () => _changeRole(u),
        ),
      ),
    );
  }

  Widget _reportListTile(ReportModel r) {
    final statusColor = r.status == 'Resolved' ? Colors.green : (r.status == 'Pending' ? Colors.orange : primaryBlue);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10)]),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.assignment_outlined, color: statusColor, size: 20),
        ),
        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(r.reporterName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(r.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text(r.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {}, 
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), 
                      label: const Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, elevation: 0),
                      onPressed: () {}, 
                      child: const Text("Manage", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _quickActionTile(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  Widget _buildPermissionBanner(String title, String body, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(Icons.lock_person_rounded, color: color),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(body, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
          ])),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade200),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade200),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.grey.shade400)),
    ]));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _AdminTabWrapper extends StatefulWidget {
  final Widget child;
  const _AdminTabWrapper({required this.child});
  @override
  State<_AdminTabWrapper> createState() => _AdminTabWrapperState();
}

class _AdminTabWrapperState extends State<_AdminTabWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
