import 'package:flutter/material.dart';

class AppHeroCard extends StatelessWidget {
  final IconData icon;
  final Widget? customIcon;
  final String title;
  final String subtitle;

  const AppHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F3A),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          customIcon ??
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFF5B700),
                child: Icon(icon, color: const Color(0xFF0B1F3A), size: 34),
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
