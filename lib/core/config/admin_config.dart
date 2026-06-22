class AdminConfig {
  static const adminEmails = [
    'alerttmenow@gmail.com',
    'shieldenforcement.scanbite@yahoo.com',
    'anthonyt_thomas@yahoo.com',
  ];

  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.trim().toLowerCase());
  }
}
