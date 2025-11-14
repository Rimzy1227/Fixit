import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _serviceTypeCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  File? _certFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCert() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _certFile = File(picked.path));
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _serviceTypeCtrl.dispose();
    _experienceCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerProvider() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty ||
        _serviceTypeCtrl.text.isEmpty ||
        _experienceCtrl.text.isEmpty ||
        _addressCtrl.text.isEmpty) {
      setState(() {
        _error = 'Please fill all required fields.';
        _loading = false;
      });
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() {
        _error = 'Passwords do not match.';
        _loading = false;
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      String? certUrl;
      if (_certFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('provider_certifications/${cred.user!.uid}.jpg');

        await ref.putFile(_certFile!);
        certUrl = await ref.getDownloadURL();
      }

      final contractorId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'serviceType': _serviceTypeCtrl.text.trim(),
        'experience': _experienceCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'contractorId': contractorId,
        'certificationUrl': certUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider registered successfully!"))
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Registration failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register New Provider"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Provider Information",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: "Full Name"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _emailCtrl,
                    decoration:
                        const InputDecoration(labelText: "Email Address"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: "Phone Number"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _serviceTypeCtrl,
                    decoration: const InputDecoration(
                        labelText: "Service Type (e.g., Plumber, Electrician)"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _experienceCtrl,
                    decoration: const InputDecoration(
                      labelText: "Years of Experience",
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _addressCtrl,
                    decoration:
                        const InputDecoration(labelText: "Address / Location"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "Confirm Password"),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickCert,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Upload Certificate"),
                      ),
                      const SizedBox(width: 10),
                      if (_certFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 16),

                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _registerProvider,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Register Provider"),
                          ),
                        ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
