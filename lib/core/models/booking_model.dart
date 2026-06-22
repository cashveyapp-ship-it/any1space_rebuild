class BookingModel {
  final String id;

  final String driverId;
  final String hostId;
  final String spaceId;

  final String spaceName;

  final String licensePlate;

  final double amount;

  final String status;

  final String paymentStatus;

  const BookingModel({
    required this.id,
    required this.driverId,
    required this.hostId,
    required this.spaceId,
    required this.spaceName,
    required this.licensePlate,
    required this.amount,
    required this.status,
    required this.paymentStatus,
  });

  factory BookingModel.fromMap(
    String id,
    Map<String,dynamic> map,
  ) {
    return BookingModel(
      id: id,
      driverId: map['driverId'] ?? '',
      hostId: map['hostId'] ?? '',
      spaceId: map['spaceId'] ?? '',
      spaceName: map['spaceName'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
    );
  }

  Map<String,dynamic> toMap() => {
    'driverId': driverId,
    'hostId': hostId,
    'spaceId': spaceId,
    'spaceName': spaceName,
    'licensePlate': licensePlate,
    'amount': amount,
    'status': status,
    'paymentStatus': paymentStatus,
  };
}

