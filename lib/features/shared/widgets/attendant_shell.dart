import 'package:flutter/material.dart';
import '../../attendant/screens/attendant_dashboard_screen.dart';
import '../../attendant/screens/assigned_events_screen.dart';
import '../../attendant/screens/check_in_list_screen.dart';
import '../../attendant/screens/license_plate_search_screen.dart';
import '../../attendant/screens/incident_report_screen.dart';
import '../screens/profile_screen.dart';
import 'status_gate.dart';

class AttendantShell extends StatefulWidget {
  const AttendantShell({super.key});

  @override
  State<AttendantShell> createState() => _AttendantShellState();
}

class _AttendantShellState extends State<AttendantShell> {
  int _index = 0;

  final _screens = const [
    AttendantDashboardScreen(showBackButton: false),
    AssignedEventsScreen(showBackButton: false),
    CheckInListScreen(showBackButton: false),
    LicensePlateSearchScreen(showBackButton: false),
    IncidentReportScreen(showBackButton: false),
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
            NavigationDestination(icon: Icon(Icons.local_parking_rounded), label: 'Assigned'),
            NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'Check-In'),
            NavigationDestination(icon: Icon(Icons.directions_car_rounded), label: 'Plate'),
            NavigationDestination(icon: Icon(Icons.warning_rounded), label: 'Incident'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

