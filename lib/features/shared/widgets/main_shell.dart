import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';

class MainShell extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget> children;

  const MainShell({
    super.key,
    required this.title,
    required this.children,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: children,
      ),
    );
  }
}
