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
        title: const Text('Life Safety System'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            15,
            20,
            25,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.shield,
                size: 70,
              ),

              const SizedBox(height: 15),

              const Text(
                'Select Safety Mode',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose the safety system you want to use',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // Women & Children mode
              _buildModeCard(
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

              const SizedBox(height: 18),

              // Old Person mode
              _buildModeCard(
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
            vertical: 20,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 60,
                color: color,
              ),

              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Tap to Enter',
                style: TextStyle(
                  fontSize: 16,
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