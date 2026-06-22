class AssignedSpaceModel {
  final String id;

  final String hostId;
  final String attendantId;

  final String spaceId;
  final String spaceName;

  const AssignedSpaceModel({
    required this.id,
    required this.hostId,
    required this.attendantId,
    required this.spaceId,
    required this.spaceName,
  });

  factory AssignedSpaceModel.fromMap(
    String id,
    Map<String,dynamic> map,
  ) {
    return AssignedSpaceModel(
      id: id,
      hostId: map['hostId'] ?? '',
      attendantId: map['attendantId'] ?? '',
      spaceId: map['spaceId'] ?? '',
      spaceName: map['spaceName'] ?? '',
    );
  }
}

