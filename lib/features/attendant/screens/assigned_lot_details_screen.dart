import 'package:flutter/material.dart';
import '../../../core/models/assigned_space_model.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'qr_scanner_screen.dart';
import 'check_in_list_screen.dart';
import 'incident_report_screen.dart';

class AssignedLotDetailsScreen extends StatelessWidget {
  final AssignedSpaceModel assignment;

  const AssignedLotDetailsScreen({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Assigned Lot'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            assignment.spaceName,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text('Space ID: ${assignment.spaceId}'),
          const SizedBox(height: 24),

          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('Scan QR Pass'),
              subtitle: const Text('Verify and check in a driver.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QrScannerScreen(showBackButton: true),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list_alt_rounded),
              title: const Text('Check-In List'),
              subtitle: const Text('View vehicles for this lot.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CheckInListScreen(showBackButton: true),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: const Text('Incident Report'),
              subtitle: const Text('Report unauthorized vehicles or issues.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IncidentReportScreen(showBackButton: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
