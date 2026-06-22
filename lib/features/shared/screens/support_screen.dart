import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';

class SupportScreen extends StatefulWidget {
  final bool showBackButton;

  const SupportScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _detailsController = TextEditingController();

  String _category = 'Refund Request';
  String? _bookingId;
  Map<String, dynamic>? _bookingData;
  bool _loading = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _myBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('driverId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _submit() async {
    final details = _detailsController.text.trim();

    if (_bookingId == null || _bookingData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the booking for this issue.')),
      );
      return;
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please explain the issue before submitting.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit a ticket.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': user.uid,
        'driverId': user.uid,
        'driverEmail': user.email ?? '',
        'email': user.email ?? '',
        'hostId': _bookingData?['hostId'] ?? '',
        'bookingId': _bookingId,
        'spaceId': _bookingData?['spaceId'] ?? '',
        'spaceName': _bookingData?['spaceName'] ?? '',
        'licensePlate': _bookingData?['licensePlate'] ?? '',
        'category': _category,
        'subject': _category,
        'message': details,
        'details': details,
        'status': 'open',
        'adminVisible': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _detailsController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket submitted to the host.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _prettyStatus(String value) {
    switch (value) {
      case 'inReview':
        return 'In Review';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'escalatedToAdmin':
        return 'Escalated to Admin';
      default:
        return 'Open';
    }
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _prettyStatus(status),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0B1F3A),
        ),
      ),
    );
  }

  Widget _myTickets() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('supportTickets')
          .where('driverId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Text(
              'Recent Ticket Updates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B1F3A),
              ),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data();
              final status = (data['status'] ?? 'open').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFEAF1FF),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['category'] ?? 'Support Ticket',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['spaceName'] ?? 'No space selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Support & Disputes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F3A),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text(
                  'Need Help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit a ticket to the host. Status updates will appear below.',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _myBookings(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              return DropdownButtonFormField<String>(
                initialValue: _bookingId,
                decoration: const InputDecoration(
                  labelText: 'Select Booking',
                  border: OutlineInputBorder(),
                ),
                items: docs.map((doc) {
                  final data = doc.data();

                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text('${data['spaceName'] ?? 'Booking'} • ${data['licensePlate'] ?? ''}'),
                  );
                }).toList(),
                onChanged: (value) {
                  final doc = docs.firstWhere((d) => d.id == value);
                  setState(() {
                    _bookingId = doc.id;
                    _bookingData = doc.data();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Ticket Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Refund Request', child: Text('Refund Request')),
              DropdownMenuItem(value: 'Parking Dispute', child: Text('Parking Dispute')),
              DropdownMenuItem(value: 'Damage Claim', child: Text('Damage Claim')),
              DropdownMenuItem(value: 'Towing Issue', child: Text('Towing Issue')),
              DropdownMenuItem(value: 'Payment Problem', child: Text('Payment Problem')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _detailsController,
            minLines: 7,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Explain the issue',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: const Icon(Icons.support_agent_rounded),
              label: Text(_loading ? 'Submitting...' : 'Submit Ticket'),
            ),
          ),
          _myTickets(),
        ],
      ),
    );
  }
}
