import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  final bool isLoading = false; 
  final Map<String, String> user = {
    'firstName': 'John',
    'lastName': 'Doe',
    'phoneNumber': '+1234567890',
    'email': 'admin@email.com',
    'imageUrl': 'https://media.licdn.com/dms/image/v2/D5635AQHjEiSIksEktw/profile-framedphoto-shrink_200_200/B56ZbaII3XGoAY-/0/1747416289034?e=1753020000&v=beta&t=Goc41KEA_pNtRb7YdTnDWjftBZOGxGbHqBk1vyukXg4',

  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
            Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: const BorderRadius.all(
                Radius.circular(30),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.tertiary,
                width: .5,
              ),
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        // Text(
                        //   'Profile',
                        //   style: TextStyle(
                        //     fontSize: 40,
                        //     fontWeight: FontWeight.bold,
                        //     color: Theme.of(context)
                        //         .colorScheme
                        //         .primary
                        //         .withValues(
                        //           alpha: 0.5,
                        //         ),
                        //   ),
                        // ),
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          child: user['imageUrl']!= null &&
                                  user['imageUrl']!.isNotEmpty
                              ? CircleAvatar(
                                  // Inner circle for the Icon
                                  radius:
                                      49, // Slightly smaller to create the border
                                  backgroundImage: CachedNetworkImageProvider(
                                      user['imageUrl']!),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                ),
                        ),
                        // const SizedBox(height: 20),
                        Shimmer.fromColors(
                          baseColor: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 1),
                          highlightColor: Colors.red,
                          child: Text(
                            user['lastName'] != null && user['lastName']!.isNotEmpty
                                ? user['lastName'] ?? ''
                                : user['fastName'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                        ),
                        Text(
                          user['phoneNumber']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          user['email']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Manage Users'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(context, '/user-management');
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
            onTap: () {
              context.read<AuthBloc>().add(SignOutEvent());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      
    );
  }
}