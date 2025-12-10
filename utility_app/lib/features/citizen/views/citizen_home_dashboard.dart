import 'package:flutter/material.dart';
import 'package:utility_app/features/citizen/views/leader_board.dart';
import 'package:utility_app/features/citizen/views/report_issue_screen.dart';
import 'package:utility_app/features/citizen/views/track_report_screen.dart';

class CitizenHomeDashboard extends StatefulWidget {
  const CitizenHomeDashboard({super.key});

  @override
  State<CitizenHomeDashboard> createState() => _CitizenHomeDashboardState();
}

class _CitizenHomeDashboardState extends State<CitizenHomeDashboard> {
  // ✅ Future-ready variables (can be updated from API later)
  int userReports = 12;
  int userPoints = 245;
  int userRank = 23;
  int nearbyIssues = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF057060),
        elevation: 0,
        title: const Text(
          "Citizen Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refreshDashboard, // 👈 Pull to refresh feature
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Greeting and stats section
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff0BA4E0), Color(0xff00C27F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Good morning! 👋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ready to make your city better?",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBox("Your Reports", "$userReports"),
                        _buildStatBox("Points", "$userPoints"),
                        _buildStatBox("Rank", "#$userRank"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ✅ Quick Actions section
              const Text(
                "Quick Actions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickAction(
                      icon: Icons.report_problem,
                      label: "Report Issue",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportIssueScreen(),
                          ),
                        );
                      },
                    ),
                    _quickAction(
                      icon: Icons.track_changes,
                      label: "Track Reports",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  TrackReportScreen(),
                          ),
                        );
                      },
                    ),
                    _quickAction(
                      icon: Icons.leaderboard,
                      label: "Leaderboard",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Leaderboard(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ✅ Nearby Issues Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Nearby Issues",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/mapView'),
                    child: const Text("View Map"),
                  ),
                ],
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xffe6fff3), Color(0xffd4f6ff)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      "$nearbyIssues issues within 2km",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
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

  /// Widget for stat boxes
  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  /// Widget for quick action buttons
  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Pull to refresh logic (future-ready for Firebase or API)
  Future<void> _refreshDashboard() async {
    await Future.delayed(const Duration(seconds: 1));

    // 👇 Example of updating values without state management
    setState(() {
      userReports += 1; // mock update
      nearbyIssues = (nearbyIssues + 1) % 5;
    });
  }
}
