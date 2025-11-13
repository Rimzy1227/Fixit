import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileClientScreen extends StatefulWidget {
  const ProfileClientScreen({super.key});

  @override
  State<ProfileClientScreen> createState() => _ProfileClientScreenState();
}

class _ProfileClientScreenState extends State<ProfileClientScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  String? _error;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Pick profile image
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) setState(() => _profileImage = File(picked.path));
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  // Upload image to Firebase Storage and return download URL
  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      final ref = _storage.ref().child('client_profiles/$userId.jpg');
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      setState(() => _error = 'Image upload failed: $e');
      return null;
    }
  }

  // Save profile data to Firestore
  Future<void> _saveProfile() async {
    setState(() => _error = null);

    if (_firstCtrl.text.isEmpty ||
        _lastCtrl.text.isEmpty ||
        _addressCtrl.text.isEmpty ||
        _cityCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields.');
      return;
    }

    if (_profileImage == null) {
      setState(() => _error = 'Please upload a profile picture.');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _error = 'No authenticated user found.');
      return;
    }

    setState(() => _saving = true);

    try {
      final imageUrl = await _uploadProfileImage(user.uid);
      if (imageUrl == null) throw Exception('Image upload failed');

      await _firestore.collection('clients').doc(user.uid).set({
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': user.email,
        'profileImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );

      Navigator.pushReplacementNamed(context, '/home_client');
    } catch (e) {
      setState(() => _error = 'Error saving profile: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Client Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt,
                            size: 45, color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Upload Profile Picture',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 25),

              // Form Fields
              const Text(
                'Personal Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _firstCtrl,
                  decoration: const InputDecoration(labelText: 'First Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: _lastCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 10),
              TextField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),

              const SizedBox(height: 20),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 10),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Profile'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
