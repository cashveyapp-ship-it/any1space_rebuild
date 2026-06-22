import 'package:flutter/material.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../admin/screens/admin_users_screen.dart';
import '../../admin/screens/admin_spaces_screen.dart';
import '../../admin/screens/admin_bookings_screen.dart';
import '../../admin/screens/support_tickets_screen.dart';
import '../../admin/screens/admin_incidents_screen.dart';
import '../../admin/screens/admin_revenue_screen.dart';
import '../../admin/screens/platform_settings_screen.dart';
import '../screens/profile_screen.dart';
import 'status_gate.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(showBackButton: false),
    AdminUsersScreen(showBackButton: false),
    AdminSpacesScreen(showBackButton: false),
    AdminBookingsScreen(showBackButton: false),
    SupportTicketsScreen(showBackButton: false),
    AdminIncidentsScreen(showBackButton: false),
    AdminRevenueScreen(showBackButton: false),
    PlatformSettingsScreen(showBackButton: false),
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
            NavigationDestination(icon: Icon(Icons.people_rounded), label: 'Users'),
            NavigationDestination(icon: Icon(Icons.local_parking_rounded), label: 'Spaces'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: 'Tickets'),
            NavigationDestination(icon: Icon(Icons.warning_rounded), label: 'Incidents'),
            NavigationDestination(icon: Icon(Icons.attach_money_rounded), label: 'Revenue'),
            NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

