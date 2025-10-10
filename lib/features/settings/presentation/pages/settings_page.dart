import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:phcl_accounts/core/theme/theme_provider.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:phcl_accounts/features/settings/presentation/widgets/edit_profile_bottomsheet.dart';
import 'package:phcl_accounts/features/settings/presentation/widgets/theme_picker_dialog.dart';
import 'package:shimmer/shimmer.dart';

/// Settings page providing user profile management and app configuration options.
///
/// Offers comprehensive settings functionality including:
/// - User profile display with role-based styling
/// - Profile editing through modal bottom sheet
/// - Theme customization (light/dark mode + advanced options)
/// - Role-based access control for admin features
/// - Secure logout with confirmation dialog
/// - User management access for administrators
/// - Shimmer effects for enhanced visual appeal
///
/// The page uses BLoC pattern for state management and Provider pattern
/// for theme management, ensuring consistent user experience across the app.
/// All settings changes are persisted and immediately reflected in the UI.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// State class for SettingsPage managing user interactions and UI state.
///
/// Handles all settings-related user actions including profile management,
/// theme customization, and secure logout operations with proper error handling.
class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Settings page initialization - no additional setup required
    // as all state is managed by BLoC and Provider patterns
  }

  @override
  void dispose() {
    super.dispose();
    // No resources to clean up - stateless settings page
  }

  /// Handles secure user logout with confirmation dialog and error handling.
  ///
  /// Implements a two-step logout process for security:
  /// 1. Shows confirmation dialog to prevent accidental logouts
  /// 2. Triggers BLoC logout event which handles Firebase auth cleanup
  ///
  /// Features:
  /// - Non-dismissible confirmation dialog for intentional action
  /// - Proper context mounting checks to prevent memory leaks
  /// - Comprehensive error handling with user feedback
  /// - Automatic navigation handled by auth state changes
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs and accessing BLoC
  void _signOutUser(BuildContext context) async {
    try {
      // Show confirmation dialog to prevent accidental logout
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Force user to make conscious choice
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

      // Proceed with logout only if user confirmed and context is still valid
      if (confirmed == true && context.mounted) {
        // Trigger logout event - Firebase auth state change handles navigation
        context.read<AuthBloc>().add(SignOutEvent());
      }
    } catch (e) {
      // Handle any logout errors gracefully with user notification
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
      }
    }
  }

  /// Displays the profile editing modal bottom sheet for authenticated users.
  ///
  /// Provides a full-screen modal interface for users to update their profile
  /// information including name, contact details, and profile image.
  ///
  /// Features:
  /// - Full-screen scrollable modal for comprehensive editing
  /// - Transparent background for modern modal appearance
  /// - User data pre-population from current auth state
  /// - Automatic state validation before showing modal
  ///
  /// Parameters:
  /// - [context]: BuildContext for modal presentation and auth state access
  ///
  /// Requirements:
  /// - User must be authenticated to access profile editing
  /// - Auth state must contain valid user data
  void _showEditProfile(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    // Only show edit profile if user is properly authenticated
    if (authState is AuthAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allow full-screen modal
        backgroundColor: Colors.transparent, // Modern transparent design
        builder: (context) => EditProfileBottomSheet(user: authState.user),
      );
    }
  }

  /// Builds the main settings page UI with user profile and configuration options.
  ///
  /// Creates a comprehensive settings interface featuring:
  /// - Prominent user profile section with rounded container design
  /// - Responsive layout adapting to different auth states
  /// - Clean Material Design 3 theming throughout
  /// - Scrollable content for various screen sizes
  ///
  /// The build method uses BLoC pattern to reactively update the UI
  /// based on authentication state changes, ensuring consistent user experience.
  ///
  /// Returns:
  /// - [Widget]: Complete settings page with profile and options sections
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(8.0), // Consistent page padding
            children: [
              // User profile section with prominent styling
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(30),
                  ), // Rounded design
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 0.5, // Subtle border for definition
                  ),
                ),
                child: Center(
                  child: _buildUserProfile(
                    authState,
                  ), // Dynamic profile based on auth state
                ),
              ),

              // Settings options and configuration panel
              _buildSettingsOptions(),
            ],
          ),
        );
      },
    );
  }

  /// Builds the user profile section with dynamic content based on auth state.
  ///
  /// Displays comprehensive user information with the following features:
  /// - Large profile avatar with fallback icon for users without images
  /// - Shimmer effect on username for premium visual appeal
  /// - Contact information display (phone and email)
  /// - Role badge with color-coded styling for different user types
  /// - Proper loading and error state handling
  ///
  /// Parameters:
  /// - [authState]: Current authentication state from AuthBloc
  ///
  /// Returns:
  /// - [Widget]: User profile section adapted to current auth state
  ///
  /// State Handling:
  /// - Loading: Shows circular progress indicator
  /// - Error: Displays error message with context
  /// - Authenticated: Shows complete user profile information
  /// - Other states: Shows fallback message
  Widget _buildUserProfile(AuthState authState) {
    // Show loading indicator during authentication processes
    if (authState is AuthLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      );
    }

    // Display error information if authentication fails
    if (authState is AuthError) {
      return Padding(
        padding: EdgeInsets.all(40.0),
        child: Text('Error: ${authState.message}'),
      );
    }

    // Build complete profile for authenticated users
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      return Column(
        spacing: 8, // Consistent spacing between profile elements
        children: [
          const SizedBox(height: 20),

          // Profile avatar with network image support and fallback
          CircleAvatar(
            radius: 50, // Large profile picture for prominence
            backgroundColor: Theme.of(context).colorScheme.secondary,
            backgroundImage: user.imageUrl != null && user.imageUrl != ''
                ? NetworkImage(user.imageUrl!) // Load user's profile image
                : null,
            child: user.imageUrl == null || user.imageUrl == ''
                ? Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.surfaceDim,
                    size: 60, // Large fallback icon
                  )
                : null,
          ),

          // Username with shimmer effect for premium appearance
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.primary,
            highlightColor: Theme.of(context).colorScheme.tertiary,
            child: Text(
              user.lastName ?? 'Unknown User', // Display last name or fallback
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22, // Prominent username styling
              ),
            ),
          ),

          // Contact number display (conditional)
          if (user.contactNo != null)
            Text(user.contactNo!, style: const TextStyle(fontSize: 16)),

          // Email address display (conditional)
          if (user.email != null)
            Text(user.email!, style: const TextStyle(fontSize: 16)),

          // Role badge with color-coded styling for access level identification
          if (user.role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role!), // Dynamic color based on role
                borderRadius: BorderRadius.circular(12), // Pill-shaped badge
              ),
              child: Text(
                user.role!.toUpperCase(), // Uppercase for emphasis
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 20), // Bottom spacing
        ],
      );
    }

    // Fallback for unexpected auth states
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Text('Unable to load user data'),
    );
  }

  /// Determines appropriate color for user role badge based on access level.
  ///
  /// Implements color-coded role identification system:
  /// - Admin: Error color (red) for high-privilege indication
  /// - User: Primary color (blue) for standard access
  /// - Other: Tertiary color (green) for custom or guest roles
  ///
  /// This visual differentiation helps users and administrators quickly
  /// identify access levels and permissions within the system.
  ///
  /// Parameters:
  /// - [role]: User's role string (case-insensitive)
  ///
  /// Returns:
  /// - [Color]: Theme-appropriate color for the role badge
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Theme.of(
          context,
        ).colorScheme.error; // Red for admin (high privilege)
      case 'user':
        return Theme.of(context).colorScheme.primary; // Blue for standard user
      default:
        return Theme.of(context).colorScheme.tertiary; // Green for other roles
    }
  }

  /// Builds the settings options list with role-based access control.
  ///
  /// Creates a comprehensive settings menu with the following features:
  /// - Profile management accessible to all authenticated users
  /// - Admin-only user management with role-based visibility
  /// - Theme customization options with advanced controls
  /// - Secure logout with prominent styling for critical action
  ///
  /// Each option includes appropriate icons, clear labeling, and consistent
  /// interaction patterns following Material Design guidelines.
  ///
  /// Returns:
  /// - [Widget]: Column of settings options adapted to user permissions
  Widget _buildSettingsOptions() {
    return Column(
      children: [
        // Profile management - available to all authenticated users
        ListTile(
          leading: const Icon(Icons.account_circle),
          title: const Text('Profile'),
          trailing: const Icon(Icons.arrow_forward), // Indicates navigation
          onTap: () => _showEditProfile(context),
        ),

        // User management - admin-only feature with role-based access control
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Only display user management option for admin users
            if (state is AuthAuthenticated && state.user.role == 'admin') {
              return ListTile(
                leading: const Icon(
                  Icons.security,
                ), // Security icon for admin features
                title: const Text('Manage Users'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, '/user-management');
                },
              );
            }
            return const SizedBox.shrink(); // Hide for non-admin users
          },
        ),
        // Theme customization section with Provider pattern integration
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Column(
              children: [
                // Quick theme toggle with dynamic icon and status text
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode(context)
                        ? Icons
                              .dark_mode // Moon icon for dark theme
                        : Icons.light_mode, // Sun icon for light theme
                  ),
                  title: Text(
                    'Theme: ${themeProvider.getThemeStatusText(context)}',
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode(context),
                    onChanged: (bool value) {
                      themeProvider.toggleTheme(
                        context,
                      ); // Immediate theme switch
                    },
                  ),
                ),

                // Advanced theme customization options
                ListTile(
                  leading: const Icon(
                    Icons.palette,
                  ), // Palette icon for theming
                  title: const Text('Advanced Theme Options'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () =>
                      showThemePicker(context), // Open advanced theme picker
                ),
              ],
            );
          },
        ),

        // Logout option with prominent error styling for critical action
        ListTile(
          iconColor: Theme.of(
            context,
          ).colorScheme.error, // Red color for critical action
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.exit_to_app), // Exit icon for logout
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ), // Bold text for emphasis
          ),
          onTap: () => _signOutUser(context), // Secure logout with confirmation
        ),
      ],
    );
  }
}
