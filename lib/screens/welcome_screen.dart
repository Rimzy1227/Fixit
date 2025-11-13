import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Welcome to",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                const Text(
                  "FixIt",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Login to get started",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Login with Email",
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
