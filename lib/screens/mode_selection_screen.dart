import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'women_children_dashboard.dart';
import 'old_person_dashboard.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  Future<void> selectWomenChildren(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'safety_mode',
      'women_children',
    );

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const WomenChildrenDashboard(),
      ),
    );
  }

  Future<void> selectOldPerson(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'safety_mode',
      'old_person',
    );

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const OldPersonDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LIFE SAFETY',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
              ),
            ),
            Text(
              'SYSTEM',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            12,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.shield,
                size: 60,
              ),

              const SizedBox(height: 8),

              const Text(
                'Select Safety Mode',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

        
              const SizedBox(height: 18),

              Expanded(
                child: _buildModeCard(
                  context: context,
                  color: Colors.pink,
                  icon: Icons.family_restroom,
                  title: 'Women & Children Safety',
                  description:
                      'Live location, SOS, emergency contacts '
                      'and wearable safety',
                  onTap: () {
                    selectWomenChildren(context);
                  },
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: _buildModeCard(
                  context: context,
                  color: Colors.blue,
                  icon: Icons.elderly,
                  title: 'Old Person Safety',
                  description:
                      'Health monitoring, fall detection '
                      'and caretaker alerts',
                  onTap: () {
                    selectOldPerson(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: color,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 52,
                color: color,
              ),

              const SizedBox(height: 6),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Tap to Enter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}