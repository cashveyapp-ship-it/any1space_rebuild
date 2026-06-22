import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/space_model.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'access_control_screen.dart';

class ManageSpaceScreen extends StatefulWidget {
  final SpaceModel space;

  const ManageSpaceScreen({
    super.key,
    required this.space,
  });

  @override
  State<ManageSpaceScreen> createState() => _ManageSpaceScreenState();
}

class _ManageSpaceScreenState extends State<ManageSpaceScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _available;
  late final TextEditingController _hourly;
  late final TextEditingController _daily;
  final _rules = TextEditingController();

  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.space.name);
    _address = TextEditingController(text: widget.space.address);
    _available = TextEditingController(text: widget.space.availableSpaces.toString());
    _hourly = TextEditingController(text: widget.space.hourlyPrice.toStringAsFixed(2));
    _daily = TextEditingController(text: widget.space.dailyPrice.toStringAsFixed(2));
    _active = widget.space.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _available.dispose();
    _hourly.dispose();
    _daily.dispose();
    _rules.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('spaces').doc(widget.space.id).set({
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'availableSpaces': int.tryParse(_available.text.trim()) ?? widget.space.availableSpaces,
        'hourlyPrice': double.tryParse(_hourly.text.trim()) ?? widget.space.hourlyPrice,
        'dailyPrice': double.tryParse(_daily.text.trim()) ?? widget.space.dailyPrice,
        'rules': _rules.text.trim(),
        'isActive': _active,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSpace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Space?'),
        content: const Text('This will remove this space from driver search.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('spaces')
        .doc(widget.space.id)
        .delete();

    if (!mounted) return;
    Navigator.pop(context);
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
        title: const Text('Manage Space'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 120 + MediaQuery.of(context).padding.bottom),
        children: [
          TextField(controller: _name, decoration: _dec('Space Name')),
          const SizedBox(height: 14),
          TextField(controller: _address, decoration: _dec('Address')),
          const SizedBox(height: 14),
          TextField(controller: _available, keyboardType: TextInputType.number, decoration: _dec('Available Spaces')),
          const SizedBox(height: 14),
          TextField(controller: _hourly, keyboardType: TextInputType.number, decoration: _dec('Hourly Price')),
          const SizedBox(height: 14),
          TextField(controller: _daily, keyboardType: TextInputType.number, decoration: _dec('Daily Price')),
          const SizedBox(height: 14),
          TextField(controller: _rules, minLines: 3, maxLines: 5, decoration: _dec('Rules')),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: const Text('Space Active'),
            subtitle: const Text('Turn off to hide this space from drivers.'),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccessControlScreen(space: widget.space),
                ),
              ),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Access Control / LPR'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _deleteSpace,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete Space'),
            ),
          ),
        ],
      ),
    );
  }
}


