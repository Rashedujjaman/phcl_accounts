import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementDebugPage extends StatelessWidget {
  const UserManagementDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management Debug'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('Firestore Error Details:');
                      print('Error: ${snapshot.error}');
                      print('Stack Trace: ${snapshot.stackTrace}');
                    },
                    child: const Text('Print Debug Info'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64),
                  SizedBox(height: 16),
                  Text('No users found in Firestore'),
                  SizedBox(height: 8),
                  Text('Try creating a user first'),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${data['firstName'] ?? 'Unknown'} ${data['lastName'] ?? 'User'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${data['email'] ?? 'No email'}'),
                      Text('Role: ${data['role'] ?? 'No role'}'),
                      Text('Active: ${data['isActive'] ?? 'Unknown'}'),
                      Text('ID: ${doc.id}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Raw Data'),
                          content: SingleChildScrollView(
                            child: Text(data.toString()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
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
