// lib/screens/auth/register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isClient = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  File? _certFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCert() async {
    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _certFile = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _generalError = 'Failed to pick certification: $e');
    }
  }

  Future<void> _continue() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (!email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }
    if (pwd != confirm) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }

    // Contractor extra validation
    if (!isClient) {
      if (_firstCtrl.text.trim().isEmpty ||
          _lastCtrl.text.trim().isEmpty ||
          _nicCtrl.text.trim().isEmpty ||
          _companyCtrl.text.trim().isEmpty) {
        setState(() => _generalError = 'Please fill all contractor fields.');
        return;
      }
      if (_certFile == null) {
        setState(() => _generalError = 'Please upload your certification file.');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: pwd);

      await cred.user?.sendEmailVerification();

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/otp_verification',
          arguments: {
            'role': isClient ? 'client' : 'contractor',
            if (!isClient) 'firstName': _firstCtrl.text.trim(),
            if (!isClient) 'lastName': _lastCtrl.text.trim(),
            if (!isClient) 'nic': _nicCtrl.text.trim(),
            if (!isClient) 'company': _companyCtrl.text.trim(),
            if (!isClient) 'certFilePath': _certFile?.path,
          },
        );
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _emailError =
          e.code == 'email-already-in-use' ? 'This email is already in use' : e.message);
    } catch (e) {
      setState(() => _generalError = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _roleButton(
      {required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black),
            ),
            child: Icon(
              icon,
              size: 32,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _nicCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usableHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 60;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: usableHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create an account',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _roleButton(
                          icon: Icons.person,
                          label: 'Client',
                          selected: isClient,
                          onTap: () => setState(() => isClient = true)),
                      const SizedBox(width: 24),
                      _roleButton(
                          icon: Icons.build,
                          label: 'Contractor',
                          selected: !isClient,
                          onTap: () => setState(() => isClient = false)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (!isClient) ...[
                    TextField(
                      controller: _firstCtrl,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _lastCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'NIC Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _companyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickCert,
                          icon: const Icon(Icons.upload),
                          label: const Text("Upload Certification"),
                        ),
                        const SizedBox(width: 10),
                        if (_certFile != null)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _emailError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _passwordError,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_generalError != null)
                    Text(_generalError!,
                        style: const TextStyle(color: Colors.red)),
                  if (_generalError != null) const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Continue',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Center(
                    child: Text(
                      'Signing up means you agree to the Privacy Policy and Terms of Service',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        "Have an account? Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
