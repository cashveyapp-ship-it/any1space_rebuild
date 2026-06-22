import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/widgets/apple_back_button.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _addressController = TextEditingController();

  double? _lat;
  double? _lng;
  bool _loading = false;
  String _message = 'Enter an address or use current location.';

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _message = 'Finding location...';
    });

    try {
      final results = await locationFromAddress(address);

      if (results.isEmpty) {
        setState(() => _message = 'No location found.');
        return;
      }

      final loc = results.first;

      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _message = 'Location confirmed.';
      });
    } catch (e) {
      setState(() => _message = 'Address lookup failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _message = 'Getting current location...';
    });

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _message = 'Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      final places = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String address = '${pos.latitude}, ${pos.longitude}';

      if (places.isNotEmpty) {
        final p = places.first;
        address = [
          p.street,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].where((x) => x != null && x.toString().trim().isNotEmpty).join(', ');
      }

      _addressController.text = address;

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _message = 'Current location confirmed.';
      });
    } catch (e) {
      setState(() => _message = 'Location failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirm() {
    if (_lat == null || _lng == null || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm a location first.')),
      );
      return;
    }

    Navigator.pop(
      context,
      PickedLocation(
        latitude: _lat!,
        longitude: _lng!,
        address: _addressController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Pick Lot Location'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Lot Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _loading ? null : _searchAddress,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Confirm Address'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _useCurrentLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Use Current Location'),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: Icon(_lat == null ? Icons.info_rounded : Icons.check_circle_rounded),
              title: Text(_message),
              subtitle: Text(
                _lat == null ? 'No coordinates selected.' : 'Lat: $_lat\nLng: $_lng',
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _loading ? null : _confirm,
              icon: const Icon(Icons.check_rounded),
              label: Text(_loading ? 'Working...' : 'Use This Location'),
            ),
          ),
        ],
      ),
    );
  }
}
