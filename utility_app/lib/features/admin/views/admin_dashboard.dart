import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00C6FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header Section
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
                  const Text(
                    'City Admin Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'System-wide overview and management',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard("1247", "Total Reports", Colors.purpleAccent),
                      _buildStatCard("87.3%", "Resolved", Colors.deepPurpleAccent),
                      _buildStatCard("2.8 days", "Avg Time", Colors.blueAccent),
                      _buildStatCard("23", "Overdue", Colors.indigoAccent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Filter Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterButton("This Month"),
                _buildFilterButton("All Areas"),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("View Urgent Issues"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Stats Section
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Urgent Issues",
                    value: "23",
                    subtitle: "Requires Action",
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    title: "Active Users",
                    value: "3421",
                    subtitle: "Citizens",
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    title: "Efficiency",
                    value: "87.3%",
                    subtitle: "+2.3% from last month",
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Helper Widgets
  static Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      width: 75,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget _buildFilterButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Icon(Icons.keyboard_arrow_down, size: 18)
        ],
      ),
    );
  }

  static Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 28)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}
