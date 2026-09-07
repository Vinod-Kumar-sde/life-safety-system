import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/health_screen.dart';
import 'screens/wearable_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/women_children_dashboard.dart';
import 'screens/old_person_dashboard.dart';

void main() {
  runApp(const LifeSafetySystem());
}

class LifeSafetySystem extends StatelessWidget {
  const LifeSafetySystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life Safety System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}

// Decides which screen to open when the app starts.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    checkSavedMode();
  }

  Future<void> checkSavedMode() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString('safety_mode');

    if (!mounted) return;

    if (savedMode == 'women_children') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const WomenChildrenDashboard(),
        ),
      );
    } else if (savedMode == 'old_person') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const OldPersonDashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ModeSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Existing main navigation screen.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    HealthScreen(),
    WearableScreen(),
    SOSScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch),
            label: 'Wearable',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning),
            label: 'SOS',
          ),
        ],
      ),
    );
  }
}