import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/space_model.dart';
import '../../../core/services/access_control_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class AccessControlScreen extends StatefulWidget {
  final SpaceModel space;

  const AccessControlScreen({
    super.key,
    required this.space,
  });

  @override
  State<AccessControlScreen> createState() => _AccessControlScreenState();
}

class _AccessControlScreenState extends State<AccessControlScreen> {
  final _provider = TextEditingController();
  final _webhook = TextEditingController();
  final _notes = TextEditingController();

  bool _enabled = false;
  bool _saving = false;
  String _integrationType = 'Webhook';

  @override
  void dispose() {
    _provider.dispose();
    _webhook.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('spaces')
        .doc(widget.space.id)
        .get();

    final data = snap.data() ?? {};
    final access = Map<String, dynamic>.from(data['accessControl'] ?? {});

    setState(() {
      _enabled = access['lprEnabled'] == true || data['lprEnabled'] == true;
      _provider.text = (access['providerName'] ?? '').toString();
      _integrationType = (access['integrationType'] ?? 'Webhook').toString();
      _webhook.text = (access['webhookUrl'] ?? '').toString();
      _notes.text = (access['notes'] ?? '').toString();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await AccessControlService().saveSettings(
        spaceId: widget.space.id,
        enabled: _enabled,
        providerName: _provider.text,
        integrationType: _integrationType,
        webhookUrl: _webhook.text,
        notes: _notes.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access control settings saved.')),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Access Control'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 120 + MediaQuery.of(context).padding.bottom),
        children: [
          Card(
            child: SwitchListTile(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              title: const Text(
                'Enable LPR / Gate Integration',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Host is responsible for all hardware, gate systems, cameras, and access decisions.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _provider,
            decoration: _dec('Provider Name'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _integrationType,
            decoration: _dec('Integration Type'),
            items: const [
              DropdownMenuItem(value: 'Webhook', child: Text('Webhook')),
              DropdownMenuItem(value: 'Manual Export', child: Text('Manual Export')),
              DropdownMenuItem(value: 'Provider API', child: Text('Provider API')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _integrationType = v);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _webhook,
            decoration: _dec('Webhook / API URL Optional'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            minLines: 4,
            maxLines: 7,
            decoration: _dec('Host Notes / Setup Instructions'),
          ),
          const SizedBox(height: 18),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_rounded),
              title: Text('Any1Space Role'),
              subtitle: Text(
                'Any1Space only facilitates approved booking and license plate data. The host controls and maintains the gate/LPR system.',
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Access Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

