import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();

  bool _loading = false;
  String? _message;

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await _auth.sendPasswordReset(_email.text);
      setState(() => _message = 'Password reset email sent. Check your inbox.');
    } catch (e) {
      setState(() => _message = 'Could not send reset email: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'Reset your password',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _email,
                validator: (v) => Validators.requiredField(v, 'Email'),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _sendReset,
                  child: Text(_loading ? 'Sending...' : 'Send Reset Email'),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 18),
                Text(_message!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

