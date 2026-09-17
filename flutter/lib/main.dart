// Stack: Flutter 3.x | File: lib/main.dart
// One screen: sign up, log in, forgot password, and a logged-in panel — every button is one REST call in auth_api.dart.
import 'package:flutter/material.dart';
import 'auth_api.dart';

void main() => runApp(const AuthStarterApp());

class AuthStarterApp extends StatelessWidget {
  const AuthStarterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Auth starter',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1568B8), useMaterial3: true),
        home: const AuthScreen(),
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final api = AuthApi();
  final username = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  Map<String, dynamic>? me;
  String status = '';
  bool error = false;

  Future<void> run(String label, Future<void> Function() action) async {
    final t0 = DateTime.now();
    try {
      await action();
      setState(() { status = '$label in ${DateTime.now().difference(t0).inMilliseconds} ms'; error = false; });
    } on AuthError catch (e) {
      setState(() { status = '$label failed: ${e.code} ${e.message}'; error = true; });
    }
  }

  Future<void> refresh() async {
    try { me = await api.me(); } on AuthError catch (e) { me = null; api.sessionToken = null; status = 'session rejected: ${e.code} ${e.message}'; error = true; }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = api.sessionToken != null && me != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Auth starter')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (status.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: error ? const Color(0xFFFDECEA) : const Color(0xFFE9F5EE), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: error ? const Color(0xFFB3261E) : const Color(0xFF0F6B3F), fontFamily: 'monospace')),
          ),
        const SizedBox(height: 16),
        if (!loggedIn) ...[
          TextField(controller: username, decoration: const InputDecoration(labelText: 'username')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'email (sign up / reset)')),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'password')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () => run('signed up', () async { await api.signUp(username.text, email.text, password.text); await refresh(); }), child: const Text('Create account')),
            FilledButton.tonal(onPressed: () => run('logged in', () async { await api.logIn(username.text, password.text); await refresh(); }), child: const Text('Log in')),
            OutlinedButton(onPressed: () => run('reset e-mail requested', () => api.requestPasswordReset(email.text)), child: const Text('Send reset e-mail')),
          ]),
        ] else ...[
          Text('Logged in', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('username: ${me!['username']}\nemail: ${me!['email']}\nemailVerified: ${me!['emailVerified'] ?? false}\ncreatedAt: ${me!['createdAt']}', style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: () => run('refreshed', refresh), child: const Text('Refresh (GET /users/me)')),
            OutlinedButton(onPressed: () => run('verification e-mail sent', () => api.requestVerificationEmail(me!['email'] as String)), child: const Text('Resend verification e-mail')),
            FilledButton(onPressed: () => run('logged out', () async { await api.logOut(); me = null; }), child: const Text('Log out')),
          ]),
        ],
      ]),
    );
  }
}
