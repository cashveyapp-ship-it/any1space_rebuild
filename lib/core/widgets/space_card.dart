import 'package:flutter/material.dart';
import '../models/space_model.dart';

class SpaceCard extends StatelessWidget {
  final SpaceModel space;
  final VoidCallback onTap;

  const SpaceCard({
    super.key,
    required this.space,
    required this.onTap,
  });

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.local_parking_rounded),
        ),
        title: Text(
          space.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${space.address}\n'
          '${space.availableSpaces}/${space.totalSpaces} available • ${_money(space.hourlyPrice)}/hr',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
