import 'package:flutter/material.dart';
import '../../../core/widgets/dashboard_tile.dart';
import 'assigned_events_screen.dart';
import 'qr_scanner_screen.dart';
import 'check_in_list_screen.dart';
import 'shift_tracking_screen.dart';
import 'incident_report_screen.dart';
import 'license_plate_search_screen.dart';
import 'attendant_payout_settings_screen.dart';

class AttendantDashboardScreen extends StatelessWidget {
  final bool showBackButton;

  const AttendantDashboardScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 42),
          const Text(
            'Attendant Dashboard',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify QR passes, manage check-ins, and report lot issues.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              DashboardTile(
                icon: Icons.event_note_rounded,
                title: 'Assigned Lots',
                subtitle: 'View assigned spaces.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssignedEventsScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR',
                subtitle: 'Verify booking passes.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QrScannerScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.list_alt_rounded,
                title: 'Check-In',
                subtitle: 'Manage checked-in cars.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckInListScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.timer_rounded,
                title: 'Shift',
                subtitle: 'Track work hours.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShiftTrackingScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.directions_car_rounded,
                title: 'Plate Search',
                subtitle: 'Find bookings by plate.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LicensePlateSearchScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Payouts',
                subtitle: 'Set up attendant payments.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendantPayoutSettingsScreen(showBackButton: true),
                  ),
                ),
              ),
              DashboardTile(
                icon: Icons.warning_amber_rounded,
                title: 'Incident',
                subtitle: 'Report lot issues.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IncidentReportScreen(showBackButton: true),
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



