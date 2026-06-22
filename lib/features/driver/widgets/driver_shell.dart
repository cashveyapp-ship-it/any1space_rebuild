import 'package:flutter/material.dart';

import '../screens/driver_home_screen.dart';
import '../screens/map_search_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/saved_spaces_screen.dart';
import '../screens/driver_notifications_screen.dart';
import '../../shared/screens/profile_screen.dart';
import '../../shared/widgets/status_gate.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  final _screens = const [
    DriverHomeScreen(showBackButton: false),
    MapSearchScreen(showBackButton: false),
    MyBookingsScreen(showBackButton: false),
    SavedSpacesScreen(showBackButton: false),
    DriverNotificationsScreen(showBackButton: false),
    ProfileScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return StatusGate(
      child: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
          height: 70,
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Find'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Saved'),
            NavigationDestination(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
