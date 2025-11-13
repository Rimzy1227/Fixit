import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _settingsItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Account"),
              _settingsItem(
                title: "Account Information",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account Information clicked")),
                  );
                },
              ),
              _settingsItem(
                title: "Create Admin Account",
                onTap: () => Navigator.pushNamed(context, '/create_admin_account'),
              ),
              const SizedBox(height: 16),
              _sectionTitle("Firms"),
              _settingsItem(
                title: "Contracting Firms Information",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contracting Firms clicked")),
                  );
                },
              ),
              _settingsItem(
  title: "Registration Approvals",
  onTap: () => Navigator.pushNamed(context, '/contractor_approvals'),
),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        onTap: (index) {
          // handle navigation if needed
        },
      ),
    );
  }
}
