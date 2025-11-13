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

  //
  // 🔹 EMAIL VERIFICATION CHECK
  //
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
              'Email not verified yet. Please click the verification link in your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Verification check failed: $e';
      });
    }
  }

  //
  // 🔹 PHONE OTP VERIFY
  //
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

  //
  // 🔹 OTP FIELD BUILDER
  //
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

  //
  // 🔹 AUTO CHECK EMAIL VERIFICATION EVERY 5s
  //
  void _startAutoCheck(String email, String role) {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkEmailVerified(email, role, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final method = args['method'] as String? ?? 'email';
    final role = args['role'] as String? ?? 'client';
    final verificationId = args['verificationId'] as String? ?? '';
    final phone = args['phone'] as String? ?? '';
    final email = args['email'] as String? ?? '';

    // start auto-check if email verification
    if (method == 'email' && _autoCheckTimer == null) {
      _startAutoCheck(email, role);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (method == 'email') ...[
                  const Icon(Icons.email_outlined,
                      size: 80, color: Colors.black),
                  const SizedBox(height: 20),
                  Text(
                    'We sent a verification link to your email:\n$email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'After clicking the link, press below:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _checkEmailVerified(email, role),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Check Verification'),
                          ),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && !user.emailVerified) {
                          await user.sendEmailVerification();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Verification email resent')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('No user or already verified.')),
                          );
                        }
                      } catch (e) {
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Resend failed: $e')),
                        );
                      }
                    },
                    child: const Text('Resend Email'),
                  ),
                ] else ...[
                  const Icon(Icons.sms_outlined,
                      size: 80, color: Colors.black),
                  const SizedBox(height: 20),
                  Text(
                    'Enter the 6-digit code sent to $phone',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (i) => _pinField(i),
                    ).intersperse(const SizedBox(width: 8)),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _verifyPhone(verificationId, role),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Submit'),
                          ),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tap resend on the previous screen to get a new code.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Resend Code'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// Helper extension — add spacing between widgets in a list
//
extension _ListUtils<T> on List<T> {
  List<T> intersperse(T item) {
    if (length <= 1) return [...this];
    final res = <T>[];
    for (var i = 0; i < length; i++) {
      res.add(this[i]);
      if (i != length - 1) res.add(item);
    }
    return res;
  }
}
