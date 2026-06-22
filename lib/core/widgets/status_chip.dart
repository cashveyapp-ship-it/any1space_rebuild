import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({
    super.key,
    required this.status,
  });

  Color get _color {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'checkedin':
      case 'checkedIn':
        return Colors.blue;
      case 'checkedout':
      case 'checkedOut':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: _color,
    );
  }
}
