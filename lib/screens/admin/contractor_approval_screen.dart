import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorApprovalScreen extends StatefulWidget {
  const ContractorApprovalScreen({super.key});

  @override
  State<ContractorApprovalScreen> createState() => _ContractorApprovalScreenState();
}

class _ContractorApprovalScreenState extends State<ContractorApprovalScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _updateApproval(String uid, bool approve) async {
    try {
      await _firestore.collection('contractors').doc(uid).update({
        'approved': approve,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar(
        approve ? 'Contractor approved' : 'Contractor rejected',
        color: approve ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showSnackBar('Error updating status: $e', color: Colors.red);
    }
  }

  Future<void> _deleteContractor(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Contractor?'),
        content: const Text('This will permanently delete this contractor’s account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('contractors').doc(uid).delete();
        _showSnackBar('Contractor removed', color: Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Contractor Approvals', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('contractors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No contractors found.'));
          }

          final contractors = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: contractors.length,
              itemBuilder: (context, index) {
                final contractor = contractors[index];
                final data = contractor.data() as Map<String, dynamic>? ?? {};
                final approved = data['approved'] == true;
                final name = data['name'] as String? ?? 'Unnamed Contractor';
                final email = data['email'] as String? ?? '';
                final company = data['company'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: approved ? Colors.green : Colors.orange,
                      child: Icon(
                        approved ? Icons.verified : Icons.hourglass_empty,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text('$email\n$company'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: () => _updateApproval(contractor.id, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () => _updateApproval(contractor.id, false),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          tooltip: 'Delete',
                          onPressed: () => _deleteContractor(contractor.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
