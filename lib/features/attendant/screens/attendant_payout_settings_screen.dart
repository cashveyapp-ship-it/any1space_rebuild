import 'package:flutter/material.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class AttendantPayoutSettingsScreen extends StatefulWidget {
  final bool showBackButton;

  const AttendantPayoutSettingsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<AttendantPayoutSettingsScreen> createState() => _AttendantPayoutSettingsScreenState();
}

class _AttendantPayoutSettingsScreenState extends State<AttendantPayoutSettingsScreen> {
  bool _loading = false;
  Map<String, dynamic> _status = {};

  Future<void> _loadStatus() async {
    setState(() => _loading = true);

    try {
      final status = await StripeService().checkAttendantConnectStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe status error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startOnboarding() async {
    setState(() => _loading = true);

    try {
      await StripeService().openAttendantConnectOnboarding();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe onboarding error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final chargesEnabled = _status['chargesEnabled'] == true;
    final payoutsEnabled = _status['payoutsEnabled'] == true;
    final complete = chargesEnabled && payoutsEnabled;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.showBackButton ? const AppleBackButton() : null,
        title: const Text('Attendant Payouts'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 110 + MediaQuery.of(context).padding.bottom),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                complete ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: complete ? Colors.green : Colors.orange,
              ),
              title: Text(
                complete ? 'Ready to Receive Payments' : 'Payout Setup Needed',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Charges Enabled: $chargesEnabled\nPayouts Enabled: $payoutsEnabled',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 18),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_rounded),
              title: Text('How Attendant Payment Works'),
              subtitle: Text(
                'Hosts may pay attendants through Any1Space. Any1Space adds a 3% service fee to the host payment.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _startOnboarding,
              icon: const Icon(Icons.account_balance_rounded),
              label: Text(_loading ? 'Loading...' : 'Start / Continue Stripe Setup'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _loadStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Status'),
          ),
        ],
      ),
    );
  }
}

