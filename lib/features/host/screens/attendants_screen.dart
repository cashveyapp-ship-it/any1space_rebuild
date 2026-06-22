import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/attendant_assignment_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'assign_attendant_screen.dart';
import 'attendant_details_screen.dart';

class AttendantsScreen extends StatelessWidget {
  final bool showBackButton;

  const AttendantsScreen({
    super.key,
    this.showBackButton = true,
  });

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final rateController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Attendant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hourly Rate'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await AttendantAssignmentService().addAttendant(
                  name: nameController.text,
                  email: emailController.text,
                  hourlyRate: double.tryParse(rateController.text) ?? 0,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      emailController.dispose();
      rateController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = AttendantAssignmentService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Attendants'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AssignAttendantScreen(showBackButton: true),
              ),
            ),
            icon: const Icon(Icons.assignment_ind_rounded),
          ),
          IconButton(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.streamHostAttendants(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No attendants yet.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = (data['name'] ?? 'Attendant').toString();
              final email = (data['email'] ?? '').toString();
              final rate = ((data['hourlyRate'] ?? 0) as num).toDouble();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '$email\nRate: \$${rate.toStringAsFixed(2)}/hr',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendantDetailsScreen(
                        attendantId: doc.id,
                      ),
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
