// lib/screens/auth/register_client.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({super.key});

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _usePhone = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    setState(() {
      _error = null;
    });

    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    if (_usePhone) {
      // ---- PHONE FLOW ----
      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Enter a valid phone number (include country code).';
        });
        return;
      }

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),

          // ✅ Auto verification (Android only)
          verificationCompleted: (PhoneAuthCredential credential) async {
            try {
              await FirebaseAuth.instance.signInWithCredential(credential);
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/profile_client');
            } catch (_) {
              // If automatic sign-in fails, user can still enter manually.
            }
          },

          // ❌ Verification failed
          verificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = e.message ?? 'Phone verification failed.';
            });
          },

          // ✅ Code sent successfully
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            setState(() => _loading = false);
            Navigator.pushNamed(
              context,
              '/otp_verification',
              arguments: {
                'method': 'phone',
                'verificationId': verificationId,
                'phone': phone,
                'role': 'client',
                'password': password,
              },
            );
          },

          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Phone verification error: $e';
        });
      }
    } else {
      // ---- EMAIL FLOW ----
      final email = _emailCtrl.text.trim();
      if (!email.contains('@')) {
        setState(() {
          _loading = false;
          _error = 'Enter a valid email address.';
        });
        return;
      }

      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await cred.user?.sendEmailVerification();

        if (!mounted) return;
        setState(() => _loading = false);

        Navigator.pushNamed(
          context,
          '/otp_verification',
          arguments: {
            'method': 'email',
            'email': email,
            'role': 'client',
          },
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e.message;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Registration failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register — Client')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Create an account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 🔘 Toggle Email / Phone
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _usePhone = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _usePhone ? Colors.white : Colors.black,
                        foregroundColor:
                            _usePhone ? Colors.black : Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Email'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _usePhone = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _usePhone ? Colors.black : Colors.white,
                        foregroundColor:
                            _usePhone ? Colors.white : Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Phone'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              if (_usePhone)
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number (with +country)',
                  ),
                )
              else
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
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password'),
              ),

              const SizedBox(height: 18),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Next / Verify'),
                      ),
              ),

              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Have an account? Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
