import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';

class LiabilityScreen extends StatelessWidget {
  final bool showBackButton;

  const LiabilityScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Terms & Liability'),
      ),
      body: ListView(
        padding: EdgeInsets.all(22),
        children: [
          Text(
            'Any1Space Terms & Liability',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 16),
          Text(
            'Any1Space is a facilitator platform. Hosts are responsible for their spaces, pricing, rules, availability, safety, attendants, disputes, refunds, and liabilities. Drivers must follow host rules and accept liability terms before booking.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}


