import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/profile/views/profile_screen.dart';
import 'package:utility_app/features/support/views/faq_screen.dart';
import 'package:utility_app/core/i18n/translation_service.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'User';
    final name = email.split('@').first;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF057060),
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2029&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF057060)),
              ),
            ),
            accountName: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(email, style: const TextStyle(fontSize: 12)),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: context.translate('profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
                _drawerItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: context.translate('faqs'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen()));
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    context.translate('settings'),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                _drawerItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: context.translate('logout'),
                  color: Colors.redAccent,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          // Role Badge and Version
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF057060).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 16, color: Color(0xFF057060)),
                      const SizedBox(width: 8),
                      Text(
                        "ROLE: ${role.toUpperCase()}",
                        style: const TextStyle(color: Color(0xFF057060), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.translate('logout')),
        content: Text(context.translate('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.translate('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF057060)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text(context.translate('logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
