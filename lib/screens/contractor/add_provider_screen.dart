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

    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      setState(() => _error = "Please enter a valid name and email");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final tempPassword = "Temp#1234"; // internal temporary password
      final newUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      final contractorId = FirebaseAuth.instance.currentUser!.uid;

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

      // Add to users collection
      await FirebaseFirestore.instance.collection('users').doc(newUser.user!.uid).set({
        'role': 'provider',
        'email': email,
        'name': name,
        'linkedTo': contractorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Provider Created"),
          content: Text(
            "$name has been added successfully!\n\n"
            "A password setup email has been sent to $email. "
            "Please ask the provider to check their inbox and spam folder.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _error = "This email is already registered";
        } else if (e.code == 'weak-password') {
          _error = "Temporary password is too weak";
        } else {
          _error = "Error: ${e.message}";
        }
      });
    } catch (e) {
      setState(() => _error = "Unexpected error: $e");
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            _saving
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: _createProvider,
                      child: const Text("Create Provider"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
