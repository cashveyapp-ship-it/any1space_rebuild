import 'package:flutter/material.dart';
import '../../../core/services/space_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class AddSpaceScreen extends StatefulWidget {
  final bool showBackButton;

  const AddSpaceScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<AddSpaceScreen> createState() => _AddSpaceScreenState();
}

class _AddSpaceScreenState extends State<AddSpaceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _totalSpaces = TextEditingController();
  final _hourlyRate = TextEditingController();
  final _dailyRate = TextEditingController();
  final _rules = TextEditingController();

  String _spaceType = 'Church';
  bool _acceptedHostLiability = false;
  bool _saving = false;

  final _spaceTypes = const [
    'Church',
    'School',
    'Private Land',
    'Business',
    'Event Venue',
    'Residential',
    'Open Lot',
  ];

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _totalSpaces.dispose();
    _hourlyRate.dispose();
    _dailyRate.dispose();
    _rules.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedHostLiability) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Host must accept liability responsibility.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await SpaceService().createSpace(
        name: _name.text.trim(),
        address: _address.text.trim(),
        totalSpaces: int.tryParse(_totalSpaces.text.trim()) ?? 0,
        hourlyPrice: double.tryParse(_hourlyRate.text.trim()) ?? 0,
        dailyPrice: double.tryParse(_dailyRate.text.trim()) ?? 0,
        spaceType: _spaceType,
        rules: _rules.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Space listed successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not list space: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Add Space / Lot'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22, 22, 22, 110 + MediaQuery.of(context).padding.bottom),
          children: [
            const Text(
              'List your space',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Turn your church, school, business, land, or event space into parking income.',
            ),
            const SizedBox(height: 22),

            TextFormField(
              controller: _name,
              validator: (v) => v == null || v.trim().isEmpty ? 'Space name required' : null,
              decoration: _dec('Space / Lot Name', Icons.local_parking_rounded),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _address,
              validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
              decoration: _dec('Address', Icons.location_on_rounded),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _spaceType,
              decoration: _dec('Space Type', Icons.business_rounded),
              items: _spaceTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _spaceType = value);
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _totalSpaces,
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.trim().isEmpty ? 'Total spaces required' : null,
              decoration: _dec('Total Spaces', Icons.format_list_numbered_rounded),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _hourlyRate,
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.trim().isEmpty ? 'Hourly rate required' : null,
              decoration: _dec('Hourly Rate', Icons.attach_money_rounded),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _dailyRate,
              keyboardType: TextInputType.number,
              decoration: _dec('Daily Rate Optional', Icons.today_rounded),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _rules,
              minLines: 3,
              maxLines: 5,
              decoration: _dec('Rules / Notes', Icons.rule_rounded),
            ),
            const SizedBox(height: 18),

            Card(
              child: CheckboxListTile(
                value: _acceptedHostLiability,
                onChanged: (v) => setState(() => _acceptedHostLiability = v ?? false),
                title: const Text(
                  'I understand I am responsible for this space',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Hosts are responsible for parking rules, safety, attendants, disputes, refunds, and liability.',
                ),
              ),
            ),
            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.add_business_rounded),
                label: Text(_saving ? 'Saving...' : 'List My Space'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


