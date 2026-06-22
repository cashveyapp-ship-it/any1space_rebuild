import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/role_redirect_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../../core/widgets/any1space_logo.dart';
import '../../../core/config/admin_config.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _role = 'driver';
  bool _accepted = false;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_role == 'admin' && !AdminConfig.isAdminEmail(_email.text)) {
      setState(() => _error = 'This email is not authorized to create an admin account.');
      return;
    }

    if (!_accepted) {
      setState(() => _error = 'You must accept the Terms & Liability Agreement.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'name': _name.text.trim(),
          'email': _email.text.trim().toLowerCase(),
          'role': _role,
          'isAdmin': _role == 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final dashboardRoute = await RoleRedirectService().dashboardRoute();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, dashboardRoute, (_) => false);
    } catch (e) {
      setState(() => _error = 'Account creation failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F3A),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Row(
                  children: [
                    Any1SpaceLogo(size: 64),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Start using Any1Space',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                validator: (v) => Validators.requiredField(v, 'Name'),
                decoration: _dec('Full Name', Icons.person_rounded),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                validator: (v) => Validators.requiredField(v, 'Email'),
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email', Icons.email_rounded),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                validator: (v) => Validators.requiredField(v, 'Password'),
                obscureText: _hidePassword,
                decoration: _dec(
                  'Password',
                  Icons.lock_rounded,
                  suffix: IconButton(
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: _dec('Account Role', Icons.badge_rounded),
                items: const [
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  DropdownMenuItem(value: 'host', child: Text('Host / Space Owner')),
                  DropdownMenuItem(value: 'attendant', child: Text('Attendant')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: const Text('I accept the Terms & Liability Agreement'),
              ),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _createAccount,
                  child: Text(_loading ? 'Creating...' : 'Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

