import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _digitCtrls = List.generate(6, (_) => TextEditingController());
  bool _loading = false;
  String? _error;
  Timer? _autoCheckTimer;

  @override
  void dispose() {
    for (final c in _digitCtrls) {
      c.dispose();
    }
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified(String email, String role,
      {bool silent = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'No current user. Please login again.';
        });
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        _autoCheckTimer?.cancel();
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          role == 'client'
              ? '/profile_client'
              : '/profile_contractor_full',
        );
      } else if (!silent) {
        setState(() {
          _loading = false;
          _error =
              'Email not verified yet. Please click the link sent to your email.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Verification check failed: $e';
      });
    }
  }

  Future<void> _verifyPhone(String verificationId, String role) async {
    final code = _digitCtrls.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        role == 'client'
            ? '/profile_client'
            : '/profile_contractor_full',
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Phone verification failed: $e';
      });
    }
  }

  Widget _pinField(int idx) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: _digitCtrls[idx],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(counterText: ''),
        onChanged: (v) {
          if (v.isNotEmpty && idx < _digitCtrls.length - 1) {
            FocusScope.of(context).nextFocus();
          } else if (v.isEmpty && idx > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  void _startAutoCheck(String email, String role) {
    _autoCheckTimer?.cancel();
    _autoCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
      _checkEmailVerified(email, role, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final method = args['method'] ?? 'email';
    final role = args['role'] ?? 'client';
    final verificationId = args['verificationId'] ?? '';
    final phone = args['phone'] ?? '';
    final email = args['email'] ?? '';

    if (method == 'email' && _autoCheckTimer == null) {
      _startAutoCheck(email, role);
    }

    final height =
        MediaQuery.of(context).size.height - kToolbarHeight - 40;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Icon(
                    method == 'email' ? Icons.email_outlined : Icons.sms_outlined,
                    size: 80,
                    color: Colors.black,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    method == 'email'
                        ? 'We sent a verification link to your email:\n$email'
                        : 'Enter the 6-digit code sent to $phone',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  if (method == 'phone')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _pinField(i),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 12),

                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (method == 'email') {
                                _checkEmailVerified(email, role);
                              } else {
                                _verifyPhone(verificationId, role);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              method == 'email'
                                  ? 'Check Verification'
                                  : 'Submit',
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () async {
                      if (method == 'email') {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && !user.emailVerified) {
                            await user.sendEmailVerification();
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Verification email resent')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Resend failed: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Tap resend on the previous screen to get a new code.')),
                        );
                      }
                    },
                    child: Text(
                      method == 'email'
                          ? 'Resend Email'
                          : 'Resend Code',
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
