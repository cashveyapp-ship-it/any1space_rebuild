import 'package:flutter/material.dart';
import '../../driver/screens/driver_home_screen.dart';
import '../../driver/screens/my_bookings_screen.dart';
import '../../driver/screens/saved_spaces_screen.dart';
import '../screens/support_screen.dart';
import '../screens/profile_screen.dart';
import 'status_gate.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  final _screens = const [
    DriverHomeScreen(showBackButton: false),
    MyBookingsScreen(showBackButton: false),
    SavedSpacesScreen(showBackButton: false),
    SupportScreen(showBackButton: false),
    ProfileScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return StatusGate(
      child: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
        height: 64,
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Saved'),
            NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: 'Support'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

