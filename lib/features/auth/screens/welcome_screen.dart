import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms & Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'Any1Space is a platform that helps drivers find and book parking spaces made available by hosts.\n\n'
            'Hosts are responsible for the spaces they list, including safety, access, pricing, availability, rules, attendants, and compliance with local laws.\n\n'
            'Drivers are responsible for entering accurate vehicle and license plate information, following host rules, and using the assigned space properly.\n\n'
            'Any1Space acts as a facilitator only. The platform may intervene in disputes, refunds, safety concerns, account blocks, or policy violations.\n\n'
            'By creating an account or using Any1Space, you agree to these terms.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _goToSignIn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _goToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFFFFC107),
                child: Icon(
                  Icons.local_parking_rounded,
                  color: Color(0xFF0B1F3A),
                  size: 54,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Any1Space',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B1F3A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Any Space. Any Time. Any1.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B1F3A),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'If you have space, you have a business.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => _goToSignIn(context),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _goToSignUp(context),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => _openTerms(context),
                  child: const Text(
                    'Terms & Privacy',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
