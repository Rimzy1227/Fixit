import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorApprovalScreen extends StatelessWidget {
  const ContractorApprovalScreen({super.key});

  Future<void> _updateApproval(String id, bool approved) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'verified': approved,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contractor Approvals"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'contractor')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final contractors = snapshot.data!.docs;

          if (contractors.isEmpty) {
            return const Center(child: Text("No contractors found."));
          }

          return ListView.builder(
            itemCount: contractors.length,
            itemBuilder: (context, index) {
              final c = contractors[index];
              final data = c.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['company_name'] ?? 'Unnamed Company'),
                  subtitle: Text("Verified: ${data['verified'] ?? false}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _updateApproval(c.id, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _updateApproval(c.id, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
