import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';

class EventParkingSearchScreen extends StatelessWidget {
  final bool showBackButton;

  const EventParkingSearchScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('Event Parking'),
      ),
      body: const Center(
        child: Text(
          'Event Parking',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

