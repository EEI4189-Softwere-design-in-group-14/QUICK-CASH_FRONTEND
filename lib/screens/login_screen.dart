import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final api = ApiClient();
    try {
      final session = await api.login(_email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomeScreen(session: session),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CircleAvatar(radius: 37, backgroundColor: Color(0xFFE0F5EA), child: Icon(Icons.account_balance_wallet_rounded, size: 39, color: Color(0xFF087F5B))),
            const SizedBox(height: 17),
            Text('QuickCash', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF087F5B))),
            const SizedBox(height: 6),
            const Text('Smart Loan Management', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 38),
            Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            const Text('Sign in with your registered email', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email, enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter your email address';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password, enabled: !_loading, obscureText: _hide,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(
                tooltip: _hide ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              )),
              validator: (value) => (value == null || value.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _loading ? null : _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 25),
            ElevatedButton(onPressed: _loading ? null : _login,
              child: _loading ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 19),
            TextButton(
              onPressed: _loading ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text('New borrower? Create an account'),
            ),
          ]),
        )),
      ))),
    );
  }
}
