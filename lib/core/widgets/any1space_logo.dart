import 'package:flutter/material.dart';

class Any1SpaceLogo extends StatelessWidget {
  final double size;

  const Any1SpaceLogo({
    super.key,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFF5B700),
      child: Icon(
        Icons.local_parking_rounded,
        size: size * 0.55,
        color: const Color(0xFF0B1F3A),
      ),
    );
  }
}

