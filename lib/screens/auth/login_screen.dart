import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter email and password.';
        _loading = false;
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw FirebaseAuthException(code: 'NO_USER', message: 'No user found.');

      // Optional: force email verification for email-based flows
      if (user.email != null && !user.emailVerified) {
        // If you want to enforce email verification, show message and return.
        // Comment out the next block if you do NOT want to enforce verification here.
        setState(() => _loading = false);
        _showEmailNotVerifiedDialog();
        return;
      }

      // Determine role by checking collections in order:
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;

      // 1) Check 'users' collection (preferred)
      final userDoc = await firestore.collection('users').doc(uid).get();

      String? role;
      if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('role')) {
        role = userDoc.data()!['role'] as String?;
      }

      // 2) Fallbacks: check 'clients', 'contractors', 'providers' collections
      if (role == null) {
        final clientDoc = await firestore.collection('clients').doc(uid).get();
        if (clientDoc.exists) role = 'client';
      }
      if (role == null) {
        final contractorDoc = await firestore.collection('contractors').doc(uid).get();
        if (contractorDoc.exists) role = 'contractor';
      }
      if (role == null) {
        // Some code paths use root 'providers' collection
        final providerDoc = await firestore.collection('providers').doc(uid).get();
        if (providerDoc.exists) role = 'provider';
      }
      if (role == null) {
        // Another fallback: provider nested under contractor (scan by uid) — lightweight query
        final provQuery = await firestore
            .collectionGroup('providers')
            .where(FieldPath.documentId, isEqualTo: uid)
            .limit(1)
            .get();
        if (provQuery.docs.isNotEmpty) role = 'provider';
      }

      // 3) If still null, default to client (or treat as unknown)
      role ??= 'client';

      // Navigate to role-specific home
      switch (role) {
        case 'client':
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home_client');
          break;
        case 'contractor':
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home_contractor');
          break;
        case 'provider':
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home_provider');
          break;
        case 'admin':
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home_admin');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication error.');
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email not verified'),
        content: const Text('Please verify your email address. A verification link was sent when you registered.'),
        actions: [
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && !user.emailVerified) {
                await user.sendEmailVerification();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email resent.')));
              }
              // ignore: use_build_context_synchronously
              Navigator.of(ctx).pop();
            },
            child: const Text('Resend'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 18),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                child: const Text('Forgot password?'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register_select'),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
