import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/attendant_assignment_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'booking_check_in_screen.dart';

class CheckInListScreen extends StatelessWidget {
  final bool showBackButton;

  const CheckInListScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsForSpace(String spaceId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('spaceId', isEqualTo: spaceId)
        .where('status', whereIn: ['paid', 'checkedIn'])
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Check-In List'),
      ),
      body: StreamBuilder(
        stream: AttendantAssignmentService().streamMyAssignedSpaces(),
        builder: (context, assignedSnap) {
          if (assignedSnap.hasError) {
            return Center(child: Text('Assigned spaces error: ${assignedSnap.error}'));
          }

          if (!assignedSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final assigned = assignedSnap.data!;

          if (assigned.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                  'No assigned spaces yet. Ask the host to assign you to a lot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: assigned.length,
            itemBuilder: (context, index) {
              final space = assigned[index];

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _bookingsForSpace(space.spaceId),
                builder: (context, bookingSnap) {
                  if (bookingSnap.hasError) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.error_rounded),
                        title: Text(space.spaceName),
                        subtitle: Text('Booking error: ${bookingSnap.error}'),
                      ),
                    );
                  }

                  final bookings = bookingSnap.data?.docs ?? [];

                  return Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.local_parking_rounded),
                      title: Text(
                        space.spaceName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text('${bookings.length} active booking(s)'),
                      children: bookings.map((doc) {
                        final data = doc.data();

                        return ListTile(
                          leading: const Icon(Icons.directions_car_rounded),
                          title: Text(data['licensePlate'] ?? 'Vehicle'),
                          subtitle: Text(
                            'Status: ${data['status'] ?? ''}\nPayment: ${data['paymentStatus'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingCheckInScreen(bookingId: doc.id),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
