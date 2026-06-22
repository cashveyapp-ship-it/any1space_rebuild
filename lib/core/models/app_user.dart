enum UserRole {
  driver,
  host,
  attendant,
  admin,
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] ?? 'driver'),
        orElse: () => UserRole.driver,
      ),
    );
  }
}

