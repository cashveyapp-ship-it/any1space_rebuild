import 'package:flutter/material.dart';

class AppleBackButton extends StatelessWidget {
  const AppleBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => Navigator.maybePop(context),
    );
  }
}

