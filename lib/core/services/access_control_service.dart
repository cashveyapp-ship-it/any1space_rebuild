import 'package:cloud_firestore/cloud_firestore.dart';

class AccessControlService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveSettings({
    required String spaceId,
    required bool enabled,
    required String providerName,
    required String integrationType,
    required String webhookUrl,
    required String notes,
  }) async {
    await _db.collection('spaces').doc(spaceId).set({
      'accessControl': {
        'lprEnabled': enabled,
        'providerName': providerName.trim(),
        'integrationType': integrationType,
        'webhookUrl': webhookUrl.trim(),
        'notes': notes.trim(),
        'hostResponsible': true,
        'any1spaceRole': 'facilitator_only',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'lprEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createApprovedPlateRecord({
    required String bookingId,
    required Map<String, dynamic> booking,
  }) async {
    final spaceId = (booking['spaceId'] ?? '').toString();
    final plate = (booking['licensePlate'] ?? '').toString().trim().toUpperCase();

    if (spaceId.isEmpty || plate.isEmpty) return;

    await _db.collection('approvedPlates').doc(bookingId).set({
      'bookingId': bookingId,
      'hostId': booking['hostId'] ?? '',
      'driverId': booking['driverId'] ?? '',
      'spaceId': spaceId,
      'spaceName': booking['spaceName'] ?? '',
      'licensePlate': plate,
      'startTime': booking['startTime'],
      'endTime': booking['endTime'],
      'status': 'approved',
      'source': 'any1space_booking',
      'any1spaceRole': 'facilitator_only',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
