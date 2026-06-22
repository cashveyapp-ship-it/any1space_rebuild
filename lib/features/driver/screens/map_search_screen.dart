import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/widgets/apple_back_button.dart';
import 'space_details_screen.dart';

class MapSearchScreen extends StatefulWidget {
  final bool showBackButton;

  const MapSearchScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  GoogleMapController? _controller;
  final TextEditingController _searchController = TextEditingController();

  final Set<Marker> _markers = {};
  QuerySnapshot<Map<String, dynamic>>? _latestSpaces;

  String _query = '';
  bool _mapReady = false;
  bool _locating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _spaces() {
    return FirebaseFirestore.instance
        .collection('spaces')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _matches(Map<String, dynamic> data) {
    if (_query.trim().isEmpty) return true;

    final q = _query.trim().toLowerCase();
    final name = (data['name'] ?? '').toString().toLowerCase();
    final address = (data['address'] ?? '').toString().toLowerCase();

    return name.contains(q) || address.contains(q);
  }

  void _buildMarkers(QuerySnapshot<Map<String, dynamic>> snap) {
    final next = <Marker>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      if (!_matches(data)) continue;

      final lat = _num(data['latitude']);
      final lng = _num(data['longitude']);
      if (lat == 0 || lng == 0) continue;

      next.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: (data['name'] ?? 'Space').toString(),
            snippet: (data['address'] ?? '').toString(),
            onTap: () => _openSpace(doc.id),
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _markers
        ..clear()
        ..addAll(next);
    });
  }

  void _openSpace(String spaceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpaceDetailsScreen(spaceId: spaceId),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;

    setState(() => _locating = true);

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          15,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _searchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _query = value);
          if (_latestSpaces != null) _buildMarkers(_latestSpaces!);
        },
        decoration: InputDecoration(
          hintText: 'Search spaces, lots, or address',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                    if (_latestSpaces != null) _buildMarkers(_latestSpaces!);
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _spaceCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final name = (data['name'] ?? 'Space').toString();
    final address = (data['address'] ?? '').toString();
    final hourly = _num(data['hourlyPrice'] ?? data['pricePerHour']);
    final available = _int(data['availableSpaces']);
    final total = _int(data['totalSpaces']);
    final cover = (data['coverPhoto'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openSpace(doc.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: cover.isNotEmpty
                    ? Image.network(
                        cover,
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _parkingBox(),
                      )
                    : _parkingBox(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pill('\$${hourly.toStringAsFixed(2)}/hr'),
                        _pill('$available/$total available'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parkingBox() {
    return Container(
      width: 74,
      height: 74,
      color: const Color(0xFFEAF1FF),
      child: const Icon(
        Icons.local_parking_rounded,
        color: Color(0xFF0B1F3A),
        size: 32,
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0B1F3A),
        ),
      ),
    );
  }

  Widget _spacesList(QuerySnapshot<Map<String, dynamic>> snap) {
    final docs = snap.docs.where((doc) => _matches(doc.data())).toList();

    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'No spaces found.',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      itemCount: docs.length,
      itemBuilder: (context, index) => _spaceCard(docs[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.of(context).size.height * 0.30;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _spaces(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _latestSpaces = snapshot.data;

          if (_mapReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _latestSpaces != null) {
                _buildMarkers(_latestSpaces!);
              }
            });
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: widget.showBackButton ? const AppleBackButton() : null,
            title: const Text('Find Spaces'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: _searchBar(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: mapHeight,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(33.7488, -84.3877),
                              zoom: 11,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: false,
                            mapToolbarEnabled: false,
                            liteModeEnabled: false,
                            onMapCreated: (controller) {
                              _controller = controller;
                              _mapReady = true;
                              if (_latestSpaces != null) {
                                _buildMarkers(_latestSpaces!);
                              }
                            },
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: FloatingActionButton.small(
                              heroTag: 'find_spaces_location_btn',
                              onPressed: _goToMyLocation,
                              child: _locating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: snapshot.hasError
                      ? Center(child: Text('Spaces failed to load: ${snapshot.error}'))
                      : !snapshot.hasData
                          ? const Center(child: CircularProgressIndicator())
                          : _spacesList(snapshot.data!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
