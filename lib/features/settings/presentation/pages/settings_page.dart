import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'),         actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],),
      body: const Center(child: Text('Settings Content')),
      
    );
  }
}