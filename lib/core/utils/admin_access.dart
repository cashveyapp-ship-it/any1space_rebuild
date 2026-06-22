class AdminAccess {
  static bool isAdminEmail(String? email) {
    final e = (email ?? '').toLowerCase().trim();
    return e == 'cashveyapp@gmail.com' || e == 'alerttmenow@gmail.com';
  }
}

