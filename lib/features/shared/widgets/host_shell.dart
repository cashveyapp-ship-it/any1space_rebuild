import 'package:flutter/material.dart';
import '../../host/screens/host_dashboard_screen.dart';
import '../../host/screens/my_spaces_screen.dart';
import '../../host/screens/host_bookings_screen.dart';
import '../../host/screens/revenue_dashboard_screen.dart';
import '../../host/screens/host_issues_screen.dart';
import '../screens/profile_screen.dart';
import 'status_gate.dart';

class HostShell extends StatefulWidget {
  const HostShell({super.key});

  @override
  State<HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<HostShell> {
  int _index = 0;

  final _screens = const [
    HostDashboardScreen(showBackButton: false),
    MySpacesScreen(showBackButton: false),
    HostBookingsScreen(showBackButton: false),
    RevenueDashboardScreen(showBackButton: false),
    HostIssuesScreen(showBackButton: false),
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
            NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.local_parking_rounded), label: 'Spaces'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Revenue'),
            NavigationDestination(icon: Icon(Icons.report_problem_rounded), label: 'Issues'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

