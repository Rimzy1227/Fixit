import 'package:flutter/material.dart';

class RegisterSelectScreen extends StatefulWidget {
  const RegisterSelectScreen({super.key});

  @override
  State<RegisterSelectScreen> createState() => _RegisterSelectScreenState();
}

class _RegisterSelectScreenState extends State<RegisterSelectScreen> {
  bool isClient = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create an account",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: _roleButton(
                      icon: Icons.person,
                      label: "Client",
                      selected: isClient,
                      onTap: () => setState(() => isClient = true),
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 120,
                    child: _roleButton(
                      icon: Icons.build,
                      label: "Contractor",
                      selected: !isClient,
                      onTap: () => setState(() => isClient = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      isClient ? '/register_client' : '/register_contractor',
                    );
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Signing up means you agree to the Privacy Policy and Terms of Service",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  "Have an account? Login",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.transparent,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.black,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.black : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
