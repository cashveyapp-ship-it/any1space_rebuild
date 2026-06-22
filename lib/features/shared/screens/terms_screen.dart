import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';

class TermsScreen extends StatelessWidget {
  final bool showBackButton;

  const TermsScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Terms & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: const [
          Text(
            'Any1Space Terms of Service',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 14),
          Text(
            'Any1Space is a platform that helps drivers find and book parking spaces made available by hosts. Any1Space facilitates listing, booking, payment, QR pass generation, reminders, and communication between drivers, hosts, attendants, and platform support.',
          ),
          SizedBox(height: 18),
          Text(
            'Host Responsibility',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Hosts are fully responsible for the spaces they list, including ownership or permission to use the space, safety, access, pricing, availability, rules, attendants, and compliance with local laws. Any1Space does not approve or inspect spaces before they are listed.',
          ),
          SizedBox(height: 18),
          Text(
            'Driver Responsibility',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Drivers are responsible for entering accurate vehicle and license plate information, following host rules, arriving during the booked time, and using the assigned space properly.',
          ),
          SizedBox(height: 18),
          Text(
            'Platform Role',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Any1Space acts as a facilitator only. The platform may intervene in disputes, safety concerns, policy violations, refunds, account blocks, or misuse of the service.',
          ),
          SizedBox(height: 18),
          Text(
            'Payments & Fees',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Any1Space may collect a platform fee from each booking. Hosts are responsible for their own taxes, payouts, attendants, and business obligations.',
          ),
          SizedBox(height: 18),
          Text(
            'Privacy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Any1Space may collect account information, booking details, license plate information, payment references, location data, support tickets, incident reports, and notification tokens to operate the service.',
          ),
          SizedBox(height: 18),
          Text(
            'Account Enforcement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Any1Space may suspend, block, or remove any driver, host, attendant, or admin account that violates platform rules, safety requirements, payment obligations, or terms of service.',
          ),
          SizedBox(height: 28),
          Text(
            'By creating an account or using Any1Space, you agree to these terms.',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
