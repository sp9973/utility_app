import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/citizen/citizen_service.dart';
import 'package:utility_app/features/citizen/views/leader_board.dart';
import 'package:utility_app/features/citizen/views/report_issue_screen.dart';
import 'package:utility_app/features/citizen/views/track_report_screen.dart';
import 'package:utility_app/features/citizen/views/report_details_screen.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'package:utility_app/core/i18n/translation_service.dart';
import 'package:utility_app/core/i18n/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:utility_app/core/widgets/app_drawer.dart';


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
    
    // Rank still needs a manual fetch or a more complex stream
    try {
      final stats = await _service.getCitizenStats();
      if (mounted) {
        setState(() {
          userRank = stats['rank'] ?? 1;
        });
      }
    } catch (e) {
      print("Error loading citizen rank: $e");
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

  Future<void> _openGoogleMaps() async {
    // 1st try: geo: URI — opens the Google Maps app directly on Android.
    // 2nd try: https fallback — opens in the browser if Maps app isn't found.
    final Uri geoUrl  = Uri.parse('geo:0,0?q=city+utility+issues');
    final Uri webUrl  = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=city+utility+issues');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        // Last resort: force-open as a plain browser link
        await launchUrl(webUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Maps: $e')),
        );
      }
    }
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          context.translate('citizen_dashboard'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: 'Change Language',
            onPressed: () => _showLanguagePicker(context),
          ),
        ],
      ),
      drawer: const AppDrawer(role: 'citizen'),
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
                      "${context.translate('hello')}, ${userEmail.split('@').first} 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.translate('ready_to_make_city_better'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getBadge(userPoints),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<List<ReportModel>>(
                      stream: _service.getMyReports(),
                      builder: (ctx, snap) {
                        final reports = snap.data ?? [];
                        final resolved = reports.where((r) => r.status == ReportStatus.resolved).length;
                        final points = resolved * 20 + reports.length * 5;
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatBox(context.translate('my_reports'), "${reports.length}", Icons.description_outlined),
                            _buildStatBox(context.translate('points'), "$points", Icons.stars_rounded),
                            _buildStatBox(context.translate('rank'), "#$userRank", Icons.leaderboard_outlined),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🌟 Latest Activity Spotlight (Real-time Stream)
              StreamBuilder<List<ReportModel>>(
                stream: _service.getMyReports(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                  final report = snapshot.data!.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.translate('latest_activity'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _buildLatestReportCard(report),
                      const SizedBox(height: 25),
                    ],
                  );
                },
              ),

              // Quick Actions
              Text(context.translate('quick_actions'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      label: context.translate('report_issue'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
                    ),
                    _quickAction(
                      icon: Icons.track_changes,
                      label: context.translate('track_reports'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => TrackReportScreen())),
                    ),
                    _quickAction(
                      icon: Icons.leaderboard,
                      label: context.translate('leaderboard'),
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
                  Text(context.translate('recent_city_issues'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

              const SizedBox(height: 25),

              // ── Map Section ──────────────────────────────────────────────
              Text(
                context.translate('city_map'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0BA4E0), Color(0xFF057060)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Row(
                  children: [
                    // Map pin icon in a circle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.translate('view_issues_on_map'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.translate('see_reported_problems'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Open Maps button
                    ElevatedButton.icon(
                      onPressed: _openGoogleMaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF057060),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(
                        context.translate('open_map'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  String _getBadge(int points) {
    if (points >= 200) return "City Hero 🎖️";
    if (points >= 100) return "Active Citizen 🏅";
    return "New Observer 🌱";
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLatestReportCard(ReportModel r) {
    final statusColor = r.status == 'Resolved'
        ? const Color(0xFF10B981)
        : r.status == 'In Progress'
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              r.status == 'Resolved'
                  ? Icons.check_circle_rounded
                  : r.status == 'In Progress'
                      ? Icons.autorenew_rounded
                      : Icons.hourglass_top_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "Status: ${r.status}",
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: r)),
            ),
          ),
        ],
      ),
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
              color: const Color(0xFF057060).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF057060), size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final lp = Provider.of<LanguageProvider>(context, listen: false);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.translate('select_language'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _langTile(lp, "English", "en"),
                      _langTile(lp, "Hindi (हिंदी)", "hi"),
                      _langTile(lp, "Bengali (বাংলা)", "bn"),
                      _langTile(lp, "Telugu (తెలుగు)", "te"),
                      _langTile(lp, "Marathi (मराठी)", "mr"),
                      _langTile(lp, "Tamil (தமிழ்)", "ta"),
                      _langTile(lp, "Gujarati (ગુજરાતી)", "gu"),
                      _langTile(lp, "Punjabi (ਪੰਜਾਬੀ)", "pa"),
                      _langTile(lp, "Kannada (ಕನ್ನಡ)", "kn"),
                      _langTile(lp, "Spanish (Español)", "es"),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _langTile(LanguageProvider lp, String title, String code) {
    final isSelected = lp.currentLocale.languageCode == code;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF057060)) : null,
      onTap: () {
        lp.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}
