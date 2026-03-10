import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/citizen/citizen_service.dart';
import 'package:utility_app/features/citizen/views/leader_board.dart';
import 'package:utility_app/features/citizen/views/report_issue_screen.dart';
import 'package:utility_app/features/citizen/views/track_report_screen.dart';

class CitizenHomeDashboard extends StatefulWidget {
  const CitizenHomeDashboard({super.key});

  @override
  State<CitizenHomeDashboard> createState() => _CitizenHomeDashboardState();
}

class _CitizenHomeDashboardState extends State<CitizenHomeDashboard> {
  final CitizenService _service = CitizenService();

  int userReports = 0;
  int userPoints = 0;
  int userRank = 0;
  int nearbyIssues = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    
    try {
      final stats = await _service.getCitizenStats();
      if (mounted) {
        setState(() {
          userReports = stats['totalReports'] ?? 0;
          userPoints = stats['points'] ?? 0;
          userRank = stats['rank'] ?? 1;
        });
      }
    } catch (e) {
      print("Error loading citizen stats: $e");
    }

    try {
      final nearbySnap = await _service.getNearbyReports(limit: 10).first;
      if (mounted) {
        setState(() {
          nearbyIssues = nearbySnap.length;
        });
      }
    } catch (e) {
      print("Error loading nearby reports: $e");
    }
    
    if (mounted) setState(() => _loadingStats = false);
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

  @override
  Widget build(BuildContext context) {
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Citizen';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF057060),
        elevation: 0,
        title: const Text(
          "Citizen Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF057060)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting banner
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0BA4E0), Color(0xFF00C27F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, ${userEmail.split('@').first} 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ready to make your city better?",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _loadingStats
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatBox("My Reports", "$userReports"),
                              _buildStatBox("Points", "$userPoints"),
                              _buildStatBox("Rank", "#$userRank"),
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Quick Actions
              const Text("Quick Actions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickAction(
                      icon: Icons.report_problem,
                      label: "Report Issue",
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
                    ),
                    _quickAction(
                      icon: Icons.track_changes,
                      label: "Track Reports",
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => TrackReportScreen())),
                    ),
                    _quickAction(
                      icon: Icons.leaderboard,
                      label: "Leaderboard",
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const Leaderboard())),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Nearby Issues
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent City Issues",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => TrackReportScreen())),
                    child: const Text("See All"),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6FFF3), Color(0xFFD4F6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      "$nearbyIssues recent issues in the city",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _quickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
