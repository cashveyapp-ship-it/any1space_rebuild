import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/apple_back_button.dart';

class SupportTicketsScreen extends StatelessWidget {
  final bool showBackButton;

  const SupportTicketsScreen({
    super.key,
    this.showBackButton = true,
  });

  Future<void> _closeTicket(String id) async {
    await FirebaseFirestore.instance.collection('supportTickets').doc(id).set({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Support Tickets'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('supportTickets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tickets = snapshot.data!.docs;

          if (tickets.isEmpty) {
            return const Center(
              child: Text(
                'No support tickets yet.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final doc = tickets[index];
              final data = doc.data();
              final status = data['status'] ?? 'open';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          status == 'closed'
                              ? Icons.check_circle_rounded
                              : Icons.support_agent_rounded,
                        ),
                        title: Text(
                          data['subject'] ?? 'Support Ticket',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          'Type: ${data['type'] ?? ''}\n'
                          'Email: ${data['email'] ?? ''}\n'
                          'Status: $status\n\n'
                          '${data['message'] ?? ''}',
                        ),
                        isThreeLine: false,
                      ),
                      if (status != 'closed')
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _closeTicket(doc.id),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Close Ticket'),
                          ),
                        ),
                    ],
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
