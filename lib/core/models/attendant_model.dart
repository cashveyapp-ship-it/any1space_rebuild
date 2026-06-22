class AttendantModel {
  final String uid;
  final String hostId;

  final String name;
  final String email;

  final bool active;

  const AttendantModel({
    required this.uid,
    required this.hostId,
    required this.name,
    required this.email,
    required this.active,
  });

  factory AttendantModel.fromMap(
    String uid,
    Map<String,dynamic> map,
  ) {
    return AttendantModel(
      uid: uid,
      hostId: map['hostId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      active: map['active'] ?? true,
    );
  }
}

