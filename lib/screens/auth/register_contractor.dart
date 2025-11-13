import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class RegisterContractorScreen extends StatefulWidget {
  const RegisterContractorScreen({super.key});

  @override
  State<RegisterContractorScreen> createState() =>
      _RegisterContractorScreenState();
}

class _RegisterContractorScreenState extends State<RegisterContractorScreen> {
  // Controllers
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _nic = TextEditingController();
  final _company = TextEditingController();

  bool _usePhone = false;
  bool _loading = false;
  String? _error;

  File? _certFile;
  final ImagePicker _picker = ImagePicker();

  // Pick certification file
  Future<void> _pickCert() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _certFile = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to pick certification: $e');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _first.dispose();
    _last.dispose();
    _nic.dispose();
    _company.dispose();
    super.dispose();
  }

  // Continue button pressed
  Future<void> _onContinue() async {
    if (!mounted) return;
    setState(() => _error = null);

    // Validate contractor fields
    if (_first.text.isEmpty ||
        _last.text.isEmpty ||
        _nic.text.isEmpty ||
        _company.text.isEmpty) {
      setState(() => _error = 'Please fill all contractor fields.');
      return;
    }

    if (_certFile == null) {
      setState(() => _error = 'Please upload your certification file.');
      return;
    }

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
      // Phone registration
      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Enter a valid phone number (+country code).';
        });
        return;
      }

      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential cred) async {
            try {
              await FirebaseAuth.instance.signInWithCredential(cred);
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(
                    context, '/profile_contractor_full');
              });
            } catch (_) {}
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = e.message ?? 'Phone verification failed.';
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            setState(() => _loading = false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(
                context,
                '/otp_verification',
                arguments: {
                  'method': 'phone',
                  'verificationId': verificationId,
                  'phone': phone,
                  'role': 'contractor',
                  'password': password,
                  'firstName': _first.text.trim(),
                  'lastName': _last.text.trim(),
                  'nic': _nic.text.trim(),
                  'company': _company.text.trim(),
                  'certFilePath': _certFile?.path,
                },
              );
            });
          },
          codeAutoRetrievalTimeout: (_) {},
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Phone verification error: $e';
        });
      }
    } else {
      // Email registration
      final email = _emailCtrl.text.trim();
      if (!email.contains('@')) {
        setState(() {
          _loading = false;
          _error = 'Enter a valid email address.';
        });
        return;
      }

      try {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await cred.user?.sendEmailVerification();

        if (!mounted) return;
        setState(() => _loading = false);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(
            context,
            '/otp_verification',
            arguments: {
              'method': 'email',
              'email': email,
              'role': 'contractor',
              'firstName': _first.text.trim(),
              'lastName': _last.text.trim(),
              'nic': _nic.text.trim(),
              'company': _company.text.trim(),
              'certFilePath': _certFile?.path,
            },
          );
        });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contractor Registration'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contractor Details',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(
                      controller: _first,
                      decoration:
                          const InputDecoration(labelText: 'First Name')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _last,
                      decoration:
                          const InputDecoration(labelText: 'Last Name')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _nic,
                      decoration: const InputDecoration(labelText: 'NIC No')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _company,
                      decoration: const InputDecoration(labelText: 'Company Name')),
                  const SizedBox(height: 20),
                  const Text('Contact Method',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                          ),
                          child: const Text('Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_usePhone)
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Mobile (+Country Code)'),
                    )
                  else
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(labelText: 'Email Address'),
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
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickCert,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Certification'),
                      ),
                      const SizedBox(width: 10),
                      if (_certFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Next / Verify'),
                          ),
                        ),
                  const SizedBox(height: 16),
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
            );
          },
        ),
      ),
    );
  }
}
