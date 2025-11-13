import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _sendResetLink() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _message = "✅ Password reset link sent to $email";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = "⚠️ ${e.message}";
      });
    } catch (e) {
      setState(() {
        _message = "⚠️ Something went wrong. Please try again.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Forgot Password?",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your email and we’ll send a link to reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _sendResetLink,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Send Reset Link",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_message != null)
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.startsWith('✅')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
