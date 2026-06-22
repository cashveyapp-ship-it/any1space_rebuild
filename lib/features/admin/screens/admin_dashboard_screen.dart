import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  final bool showBackButton;

  const AdminDashboardScreen({
    super.key,
    this.showBackButton = false,
  });

  Stream<int> _count(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Widget _metricCard({
    required String title,
    required Stream<int> stream,
    required IconData icon,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFEAF1FF),
                child: Icon(icon, color: const Color(0xFF0B1F3A), size: 21),
              ),
              const Spacer(),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B1F3A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22, 22, 22, 90 + bottomSafe),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F3A),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Monitor users, spaces, bookings, disputes, revenue, and platform activity.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.08,
              children: [
                _metricCard(title: 'Users', stream: _count('users'), icon: Icons.people_rounded),
                _metricCard(title: 'Spaces', stream: _count('spaces'), icon: Icons.local_parking_rounded),
                _metricCard(title: 'Bookings', stream: _count('bookings'), icon: Icons.receipt_long_rounded),
                _metricCard(title: 'Tickets', stream: _count('supportTickets'), icon: Icons.support_agent_rounded),
                _metricCard(title: 'Incidents', stream: _count('incidents'), icon: Icons.warning_rounded),
                _metricCard(title: 'Attendants', stream: _count('attendants'), icon: Icons.group_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
