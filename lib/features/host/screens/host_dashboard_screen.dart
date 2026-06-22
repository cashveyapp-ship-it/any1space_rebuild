import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/dashboard_tile.dart';
import 'add_space_screen.dart';
import 'my_spaces_screen.dart';
import 'host_bookings_screen.dart';
import 'revenue_dashboard_screen.dart';
import 'attendants_screen.dart';
import 'payout_settings_screen.dart';
import 'host_issues_screen.dart';

class HostDashboardScreen extends StatelessWidget {
  final bool showBackButton;

  const HostDashboardScreen({
    super.key,
    this.showBackButton = false,
  });

  Stream<int> _count(String collection) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection(collection)
        .where('hostId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Widget _metric(String title, Stream<int> stream, IconData icon) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        return Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: Text(
              '${snapshot.data ?? 0}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 42),
          const Text(
            'Host Dashboard',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your spaces, bookings, attendants, and earnings.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _metric('My Spaces', _count('spaces'), Icons.local_parking_rounded),
          _metric('Bookings', _count('bookings'), Icons.receipt_long_rounded),
          _metric('Attendants', _count('attendants'), Icons.group_rounded),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              DashboardTile(
                icon: Icons.add_business_rounded,
                title: 'Add Space',
                subtitle: 'Create a parking lot.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddSpaceScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.local_parking_rounded,
                title: 'My Spaces',
                subtitle: 'Manage parking spaces.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MySpacesScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.receipt_long_rounded,
                title: 'Bookings',
                subtitle: 'View driver bookings.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HostBookingsScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.bar_chart_rounded,
                title: 'Revenue',
                subtitle: 'Track host net.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RevenueDashboardScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.group_rounded,
                title: 'Attendants',
                subtitle: 'Assign team members.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendantsScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.report_problem_rounded,
                title: 'Host Issues',
                subtitle: 'Disputes and incidents.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HostIssuesScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Payouts',
                subtitle: 'Stripe payouts.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PayoutSettingsScreen(showBackButton: true),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




