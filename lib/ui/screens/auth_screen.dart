import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+250');
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.length < 8) {
      return;
    }
    await widget.state.register(phone, password);
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.length < 8) {
      return;
    }
    await widget.state.login(phone, password);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.state.authLoading;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003049), Color(0xFF005A7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'M-FinAgent Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Register once, then log in to see your transaction feed and coaching.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+250788000001',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 8 characters',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (widget.state.authError != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.state.authError!,
                  style: const TextStyle(color: Color(0xFF9F1239), fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: busy ? null : _register,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : _login,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}