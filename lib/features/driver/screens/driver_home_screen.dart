import 'package:flutter/material.dart';
import '../../../core/services/driver_notification_service.dart';
import '../../../core/widgets/dashboard_tile.dart';
import 'driver_notifications_screen.dart';
import 'map_search_screen.dart';
import 'my_bookings_screen.dart';
import 'saved_spaces_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  final bool showBackButton;

  const DriverHomeScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Driver Home',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B1F3A),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F3A),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFFFC107),
                    child: Icon(
                      Icons.local_parking_rounded,
                      color: Color(0xFF0B1F3A),
                      size: 36,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find space fast',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Book parking, event lots, church lots, school lots, and private spaces.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            StreamBuilder<int>(
              stream: DriverNotificationService().unreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: count > 0
                          ? const Color(0xFFEAF1FF)
                          : const Color(0xFFF1F2F6),
                      child: Icon(
                        count > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: const Color(0xFF0B1F3A),
                      ),
                    ),
                    title: Text(
                      count > 0 ? '$count New Reminder(s)' : 'Notifications',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                    subtitle: const Text(
                      'Booking reminders and host updates appear here.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverNotificationsScreen(
                          showBackButton: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                DashboardTile(
                  icon: Icons.map_rounded,
                  title: 'Find Nearby Spaces',
                  subtitle: 'Search active spaces on the map.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapSearchScreen(showBackButton: true),
                    ),
                  ),
                ),
                DashboardTile(
                  icon: Icons.history_rounded,
                  title: 'My Bookings',
                  subtitle: 'View bookings and QR passes.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyBookingsScreen(showBackButton: true),
                    ),
                  ),
                ),
                DashboardTile(
                  icon: Icons.favorite_rounded,
                  title: 'Saved Spaces',
                  subtitle: 'View favorite parking lots.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedSpacesScreen(showBackButton: true),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
