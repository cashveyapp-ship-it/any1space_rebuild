import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';

class PlatformSettingsScreen extends StatelessWidget {
  final bool showBackButton;

  const PlatformSettingsScreen({
    super.key,
    this.showBackButton = true,
  });

  Widget _item(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Platform Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _item('App Name', 'Any1Space', Icons.apps_rounded),
          _item('Platform Fee', '20%', Icons.percent_rounded),
          _item('Firebase', 'Connected to any1space', Icons.cloud_done_rounded),
          _item('Maps', 'Google Maps enabled', Icons.map_rounded),
          _item('Payments', 'Stripe functions connected', Icons.payment_rounded),
          _item('Admin Rule', 'Admin does not approve spaces', Icons.verified_user_rounded),
        ],
      ),
    );
  }
}
