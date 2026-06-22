import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/space_model.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'checkout_screen.dart';

class SpaceDetailsScreen extends StatelessWidget {
  final String spaceId;

  const SpaceDetailsScreen({
    super.key,
    required this.spaceId,
  });

  Future<void> _openDirections(String address, double latitude, double longitude) async {
    final query = latitude != 0 && longitude != 0
        ? '$latitude,$longitude'
        : Uri.encodeComponent(address);

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  SpaceModel _spaceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return SpaceModel(
      id: doc.id,
      hostId: (data['hostId'] ?? '').toString(),
      stripeAccountId: (data['stripeAccountId'] ?? data['stripeConnectedAccountId'] ?? '').toString(),
      name: (data['name'] ?? 'Space').toString(),
      address: (data['address'] ?? '').toString(),      totalSpaces: ((data['totalSpaces'] ?? 0) as num).toInt(),
      availableSpaces: ((data['availableSpaces'] ?? 0) as num).toInt(),
      hourlyPrice: ((data['hourlyPrice'] ?? data['pricePerHour'] ?? 0) as num).toDouble(),
      dailyPrice: ((data['dailyPrice'] ?? data['pricePerDay'] ?? 0) as num).toDouble(),
      latitude: ((data['latitude'] ?? 0) as num).toDouble(),
      longitude: ((data['longitude'] ?? 0) as num).toDouble(),
      isActive: data['isActive'] == true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('spaces').doc(spaceId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: const AppleBackButton(),
              title: const Text('Space Details'),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: const AppleBackButton(),
              title: const Text('Space Details'),
            ),
            body: const Center(child: Text('Space not found.')),
          );
        }

        final space = _spaceFromDoc(snapshot.data!);
        final canBook = space.isActive && space.availableSpaces > 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: const AppleBackButton(),
            title: const Text('Space Details'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                space.name,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(space.address),
              const SizedBox(height: 22),

              _infoCard(
                icon: Icons.local_parking_rounded,
                title: 'Availability',
                subtitle: '${space.availableSpaces}/${space.totalSpaces} spaces available',
              ),
              _infoCard(
                icon: Icons.attach_money_rounded,
                title: 'Price',
                subtitle: '\$${space.hourlyPrice.toStringAsFixed(2)}/hr • \$${space.dailyPrice.toStringAsFixed(2)}/day',
              ),
              _infoCard(
                icon: Icons.verified_user_rounded,
                title: 'Liability',
                subtitle: 'Any1Space facilitates booking. Host is responsible for the space.',
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(
                    space.address,
                    space.latitude,
                    space.longitude,
                  ),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Get Directions'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: canBook
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(space: space),
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.payment_rounded),
                  label: Text(canBook ? 'Book This Space' : 'No Spaces Available'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


