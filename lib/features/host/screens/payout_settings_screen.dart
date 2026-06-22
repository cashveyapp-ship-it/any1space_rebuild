import 'package:flutter/material.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/widgets/apple_back_button.dart';

class PayoutSettingsScreen extends StatefulWidget {
  final bool showBackButton;

  const PayoutSettingsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen> {
  bool _loading = false;
  Map<String, dynamic> _status = {};

  Future<void> _loadStatus() async {
    setState(() => _loading = true);

    try {
      final status = await StripeService().checkHostConnectStatus();
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
      await StripeService().openHostConnectOnboarding();
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
        title: const Text('Payout Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                complete ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: complete ? Colors.green : Colors.orange,
              ),
              title: Text(
                complete ? 'Stripe Connect Ready' : 'Stripe Connect Not Complete',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Charges Enabled: $chargesEnabled\nPayouts Enabled: $payoutsEnabled',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _loading ? null : _startOnboarding,
              icon: const Icon(Icons.account_balance_rounded),
              label: Text(_loading ? 'Loading...' : 'Start / Continue Stripe Onboarding'),
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
