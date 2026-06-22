import 'package:flutter/material.dart';
import '../../../core/services/role_redirect_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _route() async {
    final route = await RoleRedirectService().dashboardRoute();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _route();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
