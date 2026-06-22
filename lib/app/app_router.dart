import 'package:flutter/material.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';

import '../features/shared/widgets/driver_shell.dart';
import '../features/shared/widgets/host_shell.dart';
import '../features/shared/widgets/attendant_shell.dart';
import '../features/shared/widgets/admin_shell.dart';

import '../features/shared/screens/profile_screen.dart';
import '../features/shared/screens/liability_screen.dart';
import '../features/shared/screens/support_screen.dart';

class AppRouter {
  static const splash = '/';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const liability = '/liability';
  static const support = '/support';

  static const driverShell = '/driver-shell';
  static const hostShell = '/host-shell';
  static const attendantShell = '/attendant-shell';
  static const adminShell = '/admin-shell';
  static const profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    welcome: (_) => const WelcomeScreen(),
    signIn: (_) => const SignInScreen(),
    signUp: (_) => const SignUpScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
    liability: (_) => const LiabilityScreen(),
    support: (_) => const SupportScreen(),
    profile: (_) => const ProfileScreen(),

    driverShell: (_) => const DriverShell(),
    hostShell: (_) => const HostShell(),
    attendantShell: (_) => const AttendantShell(),
    adminShell: (_) => const AdminShell(),
  };
}
