import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/shift_tracking_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class ShiftTrackingScreen extends StatefulWidget {
  final bool showBackButton;

  const ShiftTrackingScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<ShiftTrackingScreen> createState() => _ShiftTrackingScreenState();
}

class _ShiftTrackingScreenState extends State<ShiftTrackingScreen> {
  bool _saving = false;

  String _time(dynamic value) {
    if (value is! Timestamp) return 'Not set';
    final dt = value.toDate();
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  Future<void> _startShift() async {
    setState(() => _saving = true);
    try {
      await ShiftTrackingService().startShift();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _endShift(String shiftId, Timestamp startedAt, double hourlyRate) async {
    setState(() => _saving = true);
    try {
      await ShiftTrackingService().endShift(shiftId, startedAt, hourlyRate);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ShiftTrackingService();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Shift Tracking'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.myShifts(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final active = docs.where((d) => (d.data()['status'] ?? '') == 'active').toList();
          final activeDoc = active.isEmpty ? null : active.first;
          final activeData = activeDoc?.data();
          final completed = docs.where((d) => (d.data()['status'] ?? '') != 'active').toList();

          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(activeDoc == null ? Icons.timer_off_rounded : Icons.timer_rounded),
                  title: Text(
                    activeDoc == null ? 'No Active Shift' : 'Shift Active',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    activeData == null
                        ? 'Start your shift when you arrive at your assigned lot.'
                        : 'Space: ${activeData['spaceName'] ?? ''}\nStarted: ${_time(activeData['startedAt'])}\nRate: ${_money(activeData['hourlyRate'])}/hr',
                  ),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _saving || activeDoc != null ? null : _startShift,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(_saving ? 'Saving...' : 'Start Shift'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _saving || activeDoc == null
                      ? null
                      : () => _endShift(
                            activeDoc.id,
                            activeData!['startedAt'] as Timestamp,
                            ((activeData['hourlyRate'] ?? 0) as num).toDouble(),
                          ),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('End Shift'),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Recent Shifts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ...completed.map((doc) {
                final data = doc.data();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_rounded),
                    title: Text(data['spaceName'] ?? 'Completed Shift'),
                    subtitle: Text(
                      'Hours: ${(((data['hoursWorked'] ?? 0) as num).toDouble()).toStringAsFixed(2)}\n'
                      'Estimated Pay: ${_money(data['estimatedPay'])}\n'
                      'Payment: ${data['paymentStatus'] ?? 'pendingHostReview'}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
