import 'package:flutter/material.dart';
import '../../../core/models/assigned_space_model.dart';
import '../../../core/services/attendant_assignment_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'assigned_lot_details_screen.dart';

class AssignedEventsScreen extends StatelessWidget {
  final bool showBackButton;

  const AssignedEventsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Assigned Spaces'),
      ),
      body: StreamBuilder<List<AssignedSpaceModel>>(
        stream: AttendantAssignmentService().streamMyAssignedSpaces(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  'Assigned spaces failed to load:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                  'No assigned spaces yet. Hosts can assign attendants to spaces.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_parking_rounded),
                  title: Text(
                    item.spaceName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('Space ID: ${item.spaceId}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignedLotDetailsScreen(assignment: item),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
