import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProviderScreen extends StatefulWidget {
  const AddProviderScreen({super.key});

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _createProvider() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      setState(() => _error = "All fields required");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Auto-create provider Auth user with temporary password
      final newUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: "provider123", // default temp password
      );

      final currentUser = FirebaseAuth.instance.currentUser!;
      final contractorId = currentUser.uid;

      // Create provider record under contractor
      await FirebaseFirestore.instance
          .collection('contractors')
          .doc(contractorId)
          .collection('providers')
          .doc(newUser.user!.uid)
          .set({
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': contractorId,
        'approved': false,
      });

      // Add to users table
      await FirebaseFirestore.instance.collection('users').doc(newUser.user!.uid).set({
        'role': 'provider',
        'email': email,
        'name': name,
        'linkedTo': contractorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider account created successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Service Provider"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
            const SizedBox(height: 20),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: _createProvider,
                    child: const Text("Create Provider"),
                  ),
          ],
        ),
      ),
    );
  }
}
