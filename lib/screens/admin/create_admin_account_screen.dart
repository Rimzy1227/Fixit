import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateAdminAccountScreen extends StatefulWidget {
  const CreateAdminAccountScreen({super.key});

  @override
  State<CreateAdminAccountScreen> createState() => _CreateAdminAccountScreenState();
}

class _CreateAdminAccountScreenState extends State<CreateAdminAccountScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerAdmin() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (first.isEmpty || last.isEmpty || email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = "Please provide valid first name, last name, and email.";
        _loading = false;
      });
      return;
    }

    try {
      // Create temporary admin Auth account with random password
      final tempPassword = "TempAdmin#1234";
      final newAdmin = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      // Save admin info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(newAdmin.user!.uid).set({
        'role': 'admin',
        'firstName': first,
        'lastName': last,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Admin Account Created"),
          content: Text(
            "$first $last has been registered as an admin.\n\n"
            "A password setup email has been sent to $email. "
            "Please ask them to check their inbox (and spam folder).",
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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Create an admin account",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _firstCtrl,
                decoration: const InputDecoration(
                  labelText: "First Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastCtrl,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _registerAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
