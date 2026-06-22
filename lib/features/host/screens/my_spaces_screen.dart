import 'package:flutter/material.dart';
import '../../../core/models/space_model.dart';
import '../../../core/services/space_service.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'space_performance_screen.dart';

class MySpacesScreen extends StatelessWidget {
  final bool showBackButton;

  const MySpacesScreen({
    super.key,
    this.showBackButton = true,
  });

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton ? const AppleBackButton() : null,
        title: const Text('My Spaces'),
      ),
      body: StreamBuilder<List<SpaceModel>>(
        stream: SpaceService().streamMySpaces(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final spaces = snapshot.data!;

          if (spaces.isEmpty) {
            return const Center(
              child: Text(
                'No spaces added yet.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_parking_rounded),
                  title: Text(
                    space.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${space.address}\n'
                    '${space.availableSpaces}/${space.totalSpaces} available • '
                    '${_money(space.hourlyPrice)}/hr',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpacePerformanceScreen(space: space),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

