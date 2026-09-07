import 'package:flutter/material.dart';
import 'screens/contacts_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/health_screen.dart';
import 'screens/wearable_screen.dart';

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
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    HealthScreen(),
    WearableScreen(),
    SOSScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch),
            label: 'Wearable',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning),
            label: 'SOS',
          ),
        ],
      ),
    );
  }
}