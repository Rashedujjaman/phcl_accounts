import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

    @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(  
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'user';

        if (role == 'admin') {
          return AdminDashboard(userData: userData);
        } else {
          return UserDashboard(userData: userData);
        }
      },
    );
  }
}


class AdminDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  int netBalance = 0;
  int totalIn = 0;
  int totalOut = 0;

  AdminDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Column(          
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8.0,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Balance: ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      netBalance.toStringAsFixed(2), 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const Divider(
                  thickness: 1,
                  height: 24,
                  color: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total In (+):',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    Text(
                      netBalance.toStringAsFixed(2), 
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Out (-):',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    Text(
                      netBalance.toStringAsFixed(2), 
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ],
                ),
                const Divider(
                  thickness: 1,
                  height: 24,
                  color: Colors.grey,
                ),
                const Text('View Report', style: TextStyle(),)
              ],
              ),
            ),
  
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/user-management');
              },
              child: const Text('Manage Users'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/transactions');
              },
              child: const Text('View All Transactions'),
            ),
          ],)
        ),
      )
    );
  }
}



class UserDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${userData['name']}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('User Dashboard', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-transaction');
              },
              child: const Text('Add Transaction'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my-transactions');
              },
              child: const Text('View My Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}