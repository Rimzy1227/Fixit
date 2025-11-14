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
    IconData? icon,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      leading: icon != null ? Icon(icon, color: Colors.black54) : null,
      onTap: onTap,
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
          child: SingleChildScrollView(
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
                  icon: Icons.person,
                ),
                _settingsItem(
                  title: "Create Admin Account",
                  onTap: () => Navigator.pushNamed(context, '/create_admin_account'),
                  icon: Icons.admin_panel_settings,
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
                  icon: Icons.business,
                ),
                _settingsItem(
                  title: "Registration Approvals",
                  onTap: () => Navigator.pushNamed(context, '/contractor_approvals'),
                  icon: Icons.how_to_reg,
                ),
              ],
            ),
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
          // TODO: Add bottom nav routing
        },
      ),
    );
  }
}
