import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/space_model.dart';
import '../../../core/services/space_service.dart';
import '../../../core/services/attendant_assignment_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class AssignAttendantScreen extends StatefulWidget {
  final bool showBackButton;

  const AssignAttendantScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<AssignAttendantScreen> createState() => _AssignAttendantScreenState();
}

class _AssignAttendantScreenState extends State<AssignAttendantScreen> {
  String? _attendantDocId;
  String? _attendantName;
  String? _attendantEmail;
  SpaceModel? _selectedSpace;
  bool _saving = false;

  Future<void> _assign() async {
    if (_attendantDocId == null || _selectedSpace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select attendant and space.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await AttendantAssignmentService().assignSpace(
        hostId: _selectedSpace!.hostId,
        attendantId: _attendantDocId!,
        attendantEmail: _attendantEmail ?? '',
        attendantName: _attendantName ?? '',
        spaceId: _selectedSpace!.id,
        spaceName: _selectedSpace!.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned $_attendantName to ${_selectedSpace!.name}.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = AttendantAssignmentService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Assign Attendant'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Choose Attendant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.streamHostAttendants(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error loading attendants: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final attendants = snapshot.data!.docs;

              if (attendants.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.person_off_rounded),
                    title: Text('No attendants added yet'),
                    subtitle: Text('Go to Attendants and tap + to add one first.'),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue: _attendantDocId,
                decoration: const InputDecoration(
                  labelText: 'Attendant',
                  border: OutlineInputBorder(),
                ),
                items: attendants.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? 'Attendant').toString();
                  final email = (data['email'] ?? '').toString();

                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(email.isEmpty ? name : '$name • $email'),
                  );
                }).toList(),
                onChanged: (value) {
                  final doc = attendants.firstWhere((d) => d.id == value);
                  final data = doc.data();

                  setState(() {
                    _attendantDocId = doc.id;
                    _attendantName = (data['name'] ?? 'Attendant').toString();
                    _attendantEmail = (data['email'] ?? '').toString();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose Space',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<SpaceModel>>(
            stream: SpaceService().streamMySpaces(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error loading spaces: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final spaces = snapshot.data!;

              if (spaces.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.local_parking_rounded),
                    title: Text('No spaces added yet'),
                    subtitle: Text('Add a space before assigning an attendant.'),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue: _selectedSpace?.id,
                decoration: const InputDecoration(
                  labelText: 'Space',
                  border: OutlineInputBorder(),
                ),
                items: spaces.map((space) {
                  return DropdownMenuItem<String>(
                    value: space.id,
                    child: Text(space.name),
                  );
                }).toList(),
                onChanged: (value) {
                  final space = spaces.firstWhere((s) => s.id == value);
                  setState(() => _selectedSpace = space);
                },
              );
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _saving ? null : _assign,
              icon: const Icon(Icons.assignment_ind_rounded),
              label: Text(_saving ? 'Assigning...' : 'Assign Attendant'),
            ),
          ),
        ],
      ),
    );
  }
}
