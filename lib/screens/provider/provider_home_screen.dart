import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  /// Sign out the provider and navigate to login screen
  Future<void> signOutAndGotoLogin(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Query jobs assigned to this provider
    final jobsQuery = FirebaseFirestore.instance
        .collection('jobs')
        .where('providerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOutAndGotoLogin(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: jobsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No assigned jobs.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['service'] ?? 'Service'),
                  subtitle: Text(
                    'Client: ${data['clientId'] ?? ''}\nStatus: ${data['status'] ?? 'Pending'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'accept') {
                        await doc.reference.update({
                          'status': 'accepted',
                          'providerResponseAt': FieldValue.serverTimestamp(),
                        });
                      } else if (value == 'decline') {
                        await doc.reference.update({
                          'status': 'declined',
                        });
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'accept', child: Text('Accept')),
                      PopupMenuItem(value: 'decline', child: Text('Decline')),
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
