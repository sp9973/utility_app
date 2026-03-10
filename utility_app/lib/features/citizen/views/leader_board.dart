import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/core/constants/app_constants.dart';

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
  bool _loading = true;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnap = await firestore
          .collection(AppCollections.users)
          .where('role', isEqualTo: 'citizen')
          .get();

      List<_LeaderEntry> entries = [];
      for (final userDoc in usersSnap.docs) {
        final uid = userDoc.id;
        final email = userDoc.data()['email'] ?? 'Unknown';
        final reportsSnap = await firestore
            .collection(AppCollections.reports)
            .where('reporterId', isEqualTo: uid)
            .get();
        final reports = reportsSnap.docs.length;
        final resolved = reportsSnap.docs
            .where((d) => d.data()['status'] == ReportStatus.resolved)
            .length;
        final points = resolved * 20 + reports * 5;
        entries.add(_LeaderEntry(
          email: email,
          uid: uid,
          reports: reports,
          resolved: resolved,
          points: points,
        ));
      }
      entries.sort((a, b) => b.points.compareTo(a.points));
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myIndex = _entries.indexWhere((e) => e.uid == _currentUid);
    final myEntry = myIndex >= 0 ? _entries[myIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF057060),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
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
