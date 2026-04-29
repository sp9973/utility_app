import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:utility_app/core/constants/app_constants.dart';
import 'package:utility_app/features/citizen/models/report_model.dart';

class _LeaderEntry {
  final String email;
  final String uid;
  final int reports;
  final int resolved;
  final int points;

  _LeaderEntry({
    required this.email,
    required this.uid,
    required this.reports,
    required this.resolved,
    required this.points,
  });
}

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  List<_LeaderEntry> _entries = [];
  Map<String, int> _categoryData = {};
  Map<String, int> _statusData = {};
  bool _loading = true;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // No manual _loadLeaderboard call needed as StreamBuilder handles it
  }

  List<_LeaderEntry> _aggregateLeaderboard(List<ReportModel> reports) {
    Map<String, _LeaderEntry> userStats = {};

    for (var r in reports) {
      final rid = r.reporterId;
      final rName = r.reporterName;
      final status = r.status;

      if (rid.isNotEmpty) {
        final isResolved = status == ReportStatus.resolved;
        final existing = userStats[rid];

        if (existing == null) {
          userStats[rid] = _LeaderEntry(
            uid: rid,
            email: rName,
            reports: 1,
            resolved: isResolved ? 1 : 0,
            points: isResolved ? 25 : 5,
          );
        } else {
          userStats[rid] = _LeaderEntry(
            uid: rid,
            email: existing.email,
            reports: existing.reports + 1,
            resolved: existing.resolved + (isResolved ? 1 : 0),
            points: existing.points + (isResolved ? 25 : 5),
          );
        }
      }
    }

    final entries = userStats.values.toList();
    entries.sort((a, b) => b.points.compareTo(a.points));
    return entries;
  }

  Map<String, int> _aggregateCategories(List<ReportModel> reports) {
    Map<String, int> categories = {};
    for (var r in reports) {
      categories[r.category] = (categories[r.category] ?? 0) + 1;
    }
    return categories;
  }

  Map<String, int> _aggregateStatuses(List<ReportModel> reports) {
    Map<String, int> statuses = {};
    for (var r in reports) {
      statuses[r.status] = (statuses[r.status] ?? 0) + 1;
    }
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppCollections.reports).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _entries.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text("Leaderboard")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final reports = snapshot.data!.docs.map((d) => 
            ReportModel.fromJson({...d.data() as Map<String, dynamic>, 'id': d.id})
          ).toList();
          
          _entries = _aggregateLeaderboard(reports);
          _categoryData = _aggregateCategories(reports);
          _statusData = _aggregateStatuses(reports);
        }

        final myIndex = _entries.indexWhere((e) => e.uid == _currentUid);
        final myEntry = myIndex >= 0 ? _entries[myIndex] : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Leaderboard",
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF057060),
            foregroundColor: Colors.white,
          ),
          body: RefreshIndicator(
            onRefresh: () async {}, // Stream handles it
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header banner
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("🏆 City Leaderboard",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("Top citizens making a difference",
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          if (myEntry != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _stat("Your Rank", "#${myIndex + 1}"),
                                _stat("Reports", "${myEntry.reports}"),
                                _stat("Points", "${myEntry.points}"),
                                _stat("Resolved", "${myEntry.resolved}"),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    _buildChartsSection(),

                    // Top 3 podium
                    if (_entries.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_entries.length >= 2) _podiumItem(_entries[1], 2, 100),
                            if (_entries.isNotEmpty) _podiumItem(_entries[0], 1, 130),
                            if (_entries.length >= 3) _podiumItem(_entries[2], 3, 80),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("All Rankings",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, i) {
                        final e = _entries[i];
                        final isMe = e.uid == _currentUid;
                        return Card(
                          color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isMe
                                ? const BorderSide(color: Color(0xFF057060), width: 1.5)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: i == 0
                                  ? Colors.amber
                                  : i == 1
                                      ? Colors.grey.shade400
                                      : i == 2
                                          ? const Color(0xFFCD7F32)
                                          : Colors.blueGrey.shade100,
                              child: Text(
                                "${i + 1}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: i < 3 ? Colors.white : Colors.black54),
                              ),
                            ),
                            title: Text(
                              e.email.split('@').first,
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text("${e.reports} reports · ${e.resolved} resolved"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF057060).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${e.points} pts",
                                style: const TextStyle(
                                    color: Color(0xFF057060),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildChartsSection() {
    if (_categoryData.isEmpty && _statusData.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📊 Community Insights",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBarChart(
                  "By Category",
                  _categoryData,
                  const [Color(0xFF057060), Color(0xFF00BFA5)],
                ),
                const SizedBox(width: 16),
                _buildBarChart(
                  "By Status",
                  _statusData,
                  const [Color(0xFFF7971E), Color(0xFFFFD200)],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBarChart(String title, Map<String, int> data, List<Color> colors) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.values.fold(0, (prev, curr) => curr > prev ? curr : prev).toDouble();
    final items = data.entries.toList();

    return Container(
      width: 280,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + 1,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= items.length) return const SizedBox.shrink();
                        final label = items[value.toInt()].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label.length > 5 ? "${label.substring(0, 5)}.." : label,
                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: items.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _podiumItem(_LeaderEntry entry, int rank, double height) {
    final colors = {1: Colors.amber, 2: Colors.grey.shade400, 3: const Color(0xFFCD7F32)};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medals[rank]!, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            entry.email.split('@').first,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text("${entry.points} pts",
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colors[rank],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            alignment: Alignment.center,
            child: Text("#$rank",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
