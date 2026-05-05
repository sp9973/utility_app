import 'package:flutter/material.dart';
import 'package:utility_app/core/i18n/translation_service.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I report a new issue?',
        'a': 'Go to the Citizen Dashboard and tap on "Report Issue". Provide a title, description, and category. You can also attach a photo and detect your location for faster resolution.'
      },
      {
        'q': 'How can I track my reported issues?',
        'a': 'You can track your reports by tapping "Track Reports" on your dashboard. It will show the real-time status of each issue you have submitted.'
      },
      {
        'q': 'What are reward points?',
        'a': 'Reward points are given for reporting valid issues and when they are successfully resolved. You can see your points and rank on the leaderboard.'
      },
      {
        'q': 'Who resolves these issues?',
        'a': 'The city authorities and departments responsible for the specific category (e.g., Water Department, Road Authority) will handle the resolution.'
      },
      {
        'q': 'Is my data secure?',
        'a': 'Yes, your data is stored securely. We only use your location to identify the issue site and your contact details to update you on progress.'
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF057060),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
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
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              title: Text(
                faqs[index]['q']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faqs[index]['a']!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
