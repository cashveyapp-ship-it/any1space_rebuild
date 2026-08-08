import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../../core/services/stripe_service.dart';
import 'assign_attendant_screen.dart';

class AttendantDetailsScreen extends StatelessWidget {
  final String attendantId;

  const AttendantDetailsScreen({
    super.key,
    required this.attendantId,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _assignedLots() {
    return FirebaseFirestore.instance
        .collection('assignedSpaces')
        .where('attendantId', isEqualTo: attendantId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendantShifts(String email) {
    return FirebaseFirestore.instance
        .collection('attendantShifts')
        .where('attendantEmail', isEqualTo: email)
        .snapshots();
  }

  Future<void> _removeAssignment(String id) async {
    await FirebaseFirestore.instance.collection('assignedSpaces').doc(id).delete();
  }

  Future<void> _removeAttendant(BuildContext context) async {
    await FirebaseFirestore.instance.collection('attendants').doc(attendantId).delete();
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> _setShiftPaymentStatus(String shiftId, String status) async {
    await FirebaseFirestore.instance.collection('attendantShifts').doc(shiftId).set({
      'paymentStatus': status,
      'paymentUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _time(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _friendlyPaymentError(Object e) {
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'failed-precondition':
          return 'This attendant has not set up their payout account yet. Ask them to complete Stripe setup in their Profile.';
        case 'not-found':
          return 'Shift not found. Please refresh and try again.';
        case 'invalid-argument':
          return 'Invalid shift data. Please check the shift details and try again.';
        case 'unauthenticated':
          return 'You must be signed in to process payments.';
        case 'internal':
          return 'Payment service error. Please try again in a moment.';
        default:
          return e.message ?? 'Payment failed (${e.code}). Please try again.';
      }
    }
    return 'Payment failed. Please check your connection and try again.';
  }

  Future<void> _payShiftInApp(BuildContext context, String shiftId) async {
    try {
      final payment = await StripeService().createAttendantShiftPaymentIntent(
        shiftId: shiftId,
      );

      await StripeService().initializePaymentSheet(
        clientSecret: payment['clientSecret'].toString(),
      );

      await StripeService().presentPaymentSheet();

      await StripeService().markAttendantShiftPaidAfterPayment(
        shiftId: shiftId,
        paymentIntentId: payment['paymentIntentId'].toString(),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendant payment completed.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyPaymentError(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Attendant Details'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('attendants').doc(attendantId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() ?? {};
          final name = (data['name'] ?? 'Attendant').toString();
          final email = (data['email'] ?? '').toString();
          final rate = ((data['hourlyRate'] ?? 0) as num).toDouble();

          return ListView(
            padding: EdgeInsets.fromLTRB(22, 22, 22, 110 + MediaQuery.of(context).padding.bottom),
            children: [
              const CircleAvatar(radius: 42, child: Icon(Icons.person_rounded, size: 42)),
              const SizedBox(height: 16),
              Center(child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
              Center(child: Text(email)),
              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money_rounded),
                  title: const Text('Hourly Rate'),
                  subtitle: Text('\$${rate.toStringAsFixed(2)}/hr'),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Assigned Lots / Spaces',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _assignedLots(),
                builder: (context, assignedSnap) {
                  if (!assignedSnap.hasData) return const LinearProgressIndicator();

                  final lots = assignedSnap.data!.docs;

                  if (lots.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.local_parking_rounded),
                        title: Text('No assigned lots yet'),
                        subtitle: Text('Tap Assign Spaces below to assign a lot.'),
                      ),
                    );
                  }

                  return Column(
                    children: lots.map((doc) {
                      final lot = doc.data();

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_parking_rounded),
                          title: Text(
                            lot['spaceName'] ?? 'Assigned Lot',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            'Status: ${lot['status'] ?? 'assigned'}\nSpace ID: ${lot['spaceId'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: () => _removeAssignment(doc.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Shift Review / Payment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _attendantShifts(email),
                builder: (context, shiftSnap) {
                  if (!shiftSnap.hasData) return const LinearProgressIndicator();

                  final shifts = shiftSnap.data!.docs.where((doc) {
                    final shift = doc.data();
                    return (shift['status'] ?? '') == 'completed';
                  }).toList();

                  if (shifts.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.timer_rounded),
                        title: Text('No completed shifts yet'),
                        subtitle: Text('Completed attendant shifts will appear here.'),
                      ),
                    );
                  }

                  return Column(
                    children: shifts.map((doc) {
                      final shift = doc.data();
                      final hours = ((shift['hoursWorked'] ?? 0) as num).toDouble();
                      final pay = shift['estimatedPay'] ?? 0;
                      final paymentStatus = (shift['paymentStatus'] ?? 'pendingHostReview').toString();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.payments_rounded),
                                title: Text(
                                  shift['spaceName'] ?? 'Completed Shift',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                subtitle: Text(
                                  'Started: ${_time(shift['startedAt'])}\n'
                                      'Ended: ${_time(shift['endedAt'])}\n'
                                      'Hours: ${hours.toStringAsFixed(2)} x ${_money(shift['hourlyRate'])}/hr\n'
                                      'Amount Due: ${_money(pay)}\n'
                                      'Payment: $paymentStatus',
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Show warning if attendant payout not set up
                              if (paymentStatus == 'pendingHostReview')
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFFCC02)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'If paying in-app, the attendant must first complete Stripe payout setup in their Profile.',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _setShiftPaymentStatus(doc.id, 'payOutsideApp'),
                                    icon: const Icon(Icons.handshake_rounded),
                                    label: const Text('Pay Outside App'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _payShiftInApp(context, doc.id),
                                    icon: const Icon(Icons.credit_card_rounded),
                                    label: const Text('Pay Attendant In App'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _setShiftPaymentStatus(doc.id, 'paidOutsideApp'),
                                    icon: const Icon(Icons.check_circle_rounded),
                                    label: const Text('Mark Paid'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AssignAttendantScreen(showBackButton: true),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_ind_rounded),
                  label: const Text('Assign Spaces'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _removeAttendant(context),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Remove Attendant'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}