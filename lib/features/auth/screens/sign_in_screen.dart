import 'package:flutter/material.dart';
import '../../../core/widgets/apple_back_button.dart';
import '../../../app/app_router.dart';
import '../../../core/widgets/any1space_logo.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/role_redirect_service.dart';
import '../../../core/utils/validators.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final route = await RoleRedirectService().dashboardRoute();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } catch (e) {
      setState(() => _error = 'Sign in failed. Please check your email and password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF0B1F3A), width: 1.6),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppleBackButton(),
        title: const Text('Sign In'),
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
                        'Welcome back to Any1Space',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                validator: (v) => Validators.requiredField(v, 'Email'),
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(label: 'Email', icon: Icons.email_rounded),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                validator: (v) => Validators.requiredField(v, 'Password'),
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: Text(_isLoading ? 'Signing in...' : 'Sign In'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.forgotPassword),
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
