import 'package:flutter/material.dart';
import '../../../core/services/user_status_service.dart';

class StatusGate extends StatefulWidget {
  final Widget child;

  const StatusGate({
    super.key,
    required this.child,
  });

  @override
  State<StatusGate> createState() => _StatusGateState();
}

class _StatusGateState extends State<StatusGate> {
  bool _checking = true;

  Future<void> _check() async {
    final route = await UserStatusService().blockedRedirectRoute();

    if (!mounted) return;

    if (route != null) {
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      return;
    }

    setState(() => _checking = false);
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.child;
  }
}
