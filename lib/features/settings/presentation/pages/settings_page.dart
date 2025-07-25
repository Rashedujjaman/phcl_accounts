import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:phcl_accounts/features/settings/presentation/widgets/edit_profile_bottomsheet.dart';
import 'package:shimmer/shimmer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _signOutUser(BuildContext context) async {
    try {
      // Show confirmation dialog first
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        // Trigger logout - Firebase auth state change should handle navigation
        context.read<AuthBloc>().add(SignOutEvent());
      }
    } catch (e) {
      // Handle any errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  void _showEditProfile(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EditProfileBottomSheet(user: authState.user),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceDim,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: .5,
                      ),
                    ),
                    child: Center(
                      child: _buildUserProfile(authState),
                    ),
                  ),
                  _buildSettingsOptions(),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildUserProfile(AuthState authState) {
    if (authState is AuthLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      );
    }

    if (authState is AuthError) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text('Error: ${authState.message}'),
      );
    }

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      return Column(
        spacing: 8,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            backgroundImage: user.imageUrl != null && user.imageUrl != ''
                ? NetworkImage(user.imageUrl!)
                : null,
            child: user.imageUrl == null || user.imageUrl == ''
                ? Icon(
                    Icons.person, 
                    color: Theme.of(context).colorScheme.surfaceDim,
                    size: 60,
                  )
                : null,
          ),
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.tertiary.withValues(alpha: 1),
            highlightColor: Colors.red,
            child: Text(
              user.lastName ?? 'Unknown User',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          if (user.contactNo != null)
            Text(
              user.contactNo!,
              style: const TextStyle(fontSize: 16),
            ),
          if (user.email != null)
            Text(
              user.email!,
              style: const TextStyle(fontSize: 16),
            ),
          if (user.role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      );
    }

    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Text('Unable to load user data'),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSettingsOptions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.account_circle),
          title: const Text('Profile'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => _showEditProfile(context),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Only show user management for admin users
            if (state is AuthAuthenticated && state.user.role == 'admin') {
              return ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Manage Users'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, '/user-management');
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            // Navigator.pushNamed(context, '/notifications');
          },
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (bool value) {
              // Provider.of<ThemeProvider>(context, listen: false)
              //     .toggleTheme();
              // Handle toggle logic here
            },
          ),
          title: const Text('Dark Mode'),
        ),
        ListTile(
          iconColor: Colors.red,
          textColor: Colors.red,
          leading: const Icon(Icons.exit_to_app),
          title: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => _signOutUser(context),
        ),
      ],
    );
  }
}
