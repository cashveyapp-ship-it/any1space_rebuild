import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';

class IncidentReportScreen extends StatefulWidget {
  final bool showBackButton;

  const IncidentReportScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _notes = TextEditingController();
  final _plate = TextEditingController();
  String _type = 'Unauthorized Vehicle';
  bool _saving = false;

  final _types = [
    'Unauthorized Vehicle',
    'Accident',
    'Vehicle Damage',
    'Property Damage',
    'Blocked Space',
    'Tow Request',
    'Security Concern',
    'Other',
  ];

  @override
  void dispose() {
    _notes.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_notes.text.trim().isEmpty) return;

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('incidents').add({
        'attendantId': user?.uid ?? '',
        'attendantEmail': user?.email ?? '',
        'type': _type,
        'licensePlate': _plate.text.trim().toUpperCase(),
        'notes': _notes.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _notes.clear();
      _plate.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident submitted.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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

  Widget _myIncidents() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .where('attendantId', isEqualTo: uid)
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
              'Recent Incident Updates',
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
                      backgroundColor: Color(0xFFFFEFEA),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['type'] ?? 'Incident',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['licensePlate'] == null || data['licensePlate'].toString().isEmpty
                                ? 'No plate entered'
                                : 'Plate: ${data['licensePlate']}',
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
        title: const Text('Incident Report'),
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
                Icon(Icons.report_problem_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text(
                  'Report Lot Issue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit incidents to the host. Status updates will show below.',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Incident Type',
              border: OutlineInputBorder(),
            ),
            items: _types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'License Plate (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _notes,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Describe the incident...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.report_problem_rounded),
              label: Text(_saving ? 'Saving...' : 'Submit Incident'),
            ),
          ),
          _myIncidents(),
        ],
      ),
    );
  }
}
