import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Firebase login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged in successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = "Something went wrong. Please try again.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            const SizedBox(height: 24),

            // Error message
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 16),

            // Login button
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

            const SizedBox(height: 16),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forgot_password'),
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Don’t have an account? Sign up
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don’t have an account? "),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/register_select'),
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                      color: Color.fromARGB(255, 20, 20, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
