class SpaceModel {
  final String id;
  final String hostId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  final int totalSpaces;
  final int availableSpaces;

  final double hourlyPrice;
  final double dailyPrice;

  final bool isActive;

  final String stripeAccountId;

  const SpaceModel({
    required this.id,
    required this.hostId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalSpaces,
    required this.availableSpaces,
    required this.hourlyPrice,
    required this.dailyPrice,
    required this.isActive,
    required this.stripeAccountId,
  });

  factory SpaceModel.fromMap(
    String id,
    Map<String,dynamic> map,
  ) {
    return SpaceModel(
      id: id,
      hostId: map['hostId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      totalSpaces: map['totalSpaces'] ?? 0,
      availableSpaces: map['availableSpaces'] ?? 0,
      hourlyPrice: (map['hourlyPrice'] ?? 0).toDouble(),
      dailyPrice: (map['dailyPrice'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? false,
      stripeAccountId: map['stripeAccountId'] ?? '',
    );
  }

  Map<String,dynamic> toMap() => {
    'hostId': hostId,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'totalSpaces': totalSpaces,
    'availableSpaces': availableSpaces,
    'hourlyPrice': hourlyPrice,
    'dailyPrice': dailyPrice,
    'isActive': isActive,
    'stripeAccountId': stripeAccountId,
  };
}

