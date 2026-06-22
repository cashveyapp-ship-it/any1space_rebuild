import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/apple_back_button.dart';

class HostIssuesScreen extends StatelessWidget {
  final bool showBackButton;

  const HostIssuesScreen({
    super.key,
    this.showBackButton = true,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _tickets() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('supportTickets')
        .where('hostId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _incidents() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('incidents')
        .where('hostId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _updateTicket(String id, String status) async {
    await FirebaseFirestore.instance.collection('supportTickets').doc(id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateIncident(String id, String status) async {
    await FirebaseFirestore.instance.collection('incidents').doc(id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _empty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _statusMenu({
    required void Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'open', child: Text('Open')),
        PopupMenuItem(value: 'inReview', child: Text('In Review')),
        PopupMenuItem(value: 'resolved', child: Text('Resolved')),
        PopupMenuItem(value: 'closed', child: Text('Closed')),
        PopupMenuItem(value: 'escalatedToAdmin', child: Text('Escalate to Admin')),
      ],
    );
  }

  Widget _disputesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _tickets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return _empty('No disputes or support tickets for your spaces yet.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: Text(
                  data['subject'] ?? data['category'] ?? 'Dispute',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Space: ${data['spaceName'] ?? ''}\n'
                  'Plate: ${data['licensePlate'] ?? ''}\n'
                  'Driver: ${data['driverEmail'] ?? data['email'] ?? ''}\n'
                  'Status: ${data['status'] ?? 'open'}\n\n'
                  '${data['message'] ?? data['details'] ?? ''}',
                ),
                isThreeLine: true,
                trailing: _statusMenu(
                  onSelected: (v) => _updateTicket(doc.id, v),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _incidentsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _incidents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return _empty('No attendant incidents for your spaces yet.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(
                  data['type'] ?? 'Incident',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Space: ${data['spaceName'] ?? data['spaceId'] ?? ''}\n'
                  'Plate: ${data['licensePlate'] ?? ''}\n'
                  'Attendant: ${data['attendantEmail'] ?? data['attendantId'] ?? ''}\n'
                  'Status: ${data['status'] ?? 'open'}\n\n'
                  '${data['notes'] ?? data['message'] ?? ''}',
                ),
                isThreeLine: true,
                trailing: _statusMenu(
                  onSelected: (v) => _updateIncident(doc.id, v),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: showBackButton ? const AppleBackButton() : null,
          title: const Text('Host Issues'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Disputes'),
              Tab(text: 'Incidents'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _disputesTab(),
            _incidentsTab(),
          ],
        ),
      ),
    );
  }
}
