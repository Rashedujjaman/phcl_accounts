import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phcl_accounts/features/admin/presentation/bloc/user_management_bloc.dart';
import 'package:phcl_accounts/features/admin/presentation/bloc/user_management_event.dart';
import 'package:phcl_accounts/features/admin/presentation/bloc/user_management_state.dart';
import 'package:phcl_accounts/features/admin/presentation/widgets/user_card.dart';
import 'package:phcl_accounts/features/admin/presentation/widgets/search_and_filter_widget.dart';
import 'package:phcl_accounts/features/admin/presentation/widgets/user_details_dialog.dart';
import 'package:phcl_accounts/features/admin/presentation/widgets/edit_user_role_dialog.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementBloc>().add(const LoadAllUsers());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.colorScheme.outline,
          ),
        ),
      ),
      body: BlocConsumer<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is UsersLoadingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is UserRoleUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is UserStatusUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UsersLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading users...'),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }

          if (state is UsersLoadingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UserManagementBloc>().add(const LoadAllUsers());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is UsersLoaded) {
            return Column(
              children: [
                SearchAndFilterWidget(
                  searchController: _searchController,
                  searchQuery: state.searchQuery,
                  selectedRoleFilter: state.selectedRoleFilter,
                  onSearchChanged: (query) {
                    context.read<UserManagementBloc>().add(SearchUsers(query));
                  },
                  onRoleFilterChanged: (role) {
                    context.read<UserManagementBloc>().add(FilterUsersByRole(role));
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    context.read<UserManagementBloc>().add(const SearchUsers(''));
                  },
                ),
                Expanded(
                  child: state.filteredUsers.isEmpty
                      ? _buildEmptyState(state.searchQuery, state.selectedRoleFilter)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = state.filteredUsers[index];
                            return UserCard(
                              user: user,
                              onEditRole: () => _showEditUserDialog(user),
                              onViewDetails: () => _showUserDetails(user),
                              onToggleStatus: (isActive) => _toggleUserStatus(user, isActive),
                            );
                          },
                        ),
                ),
              ],
            );
          }
          
          return const Center(
            child: Text('Initializing...'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        // backgroundColor: theme.colorScheme.primary,
        // foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery, String roleFilter) {
    final theme = Theme.of(context);
    String message;
    if (searchQuery.isNotEmpty) {
      message = 'No users found matching "$searchQuery"';
    } else if (roleFilter != 'all') {
      message = 'No ${roleFilter}s found';
    } else {
      message = 'No users found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(UserEntity user) {
    if (user.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User information is not available'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(user: user),
    );
  }

  void _showEditUserDialog(UserEntity user) {
    if (user.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot edit user: User ID is missing'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }
    
    final pageContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => EditUserRoleDialog(
        user: user,
        onRoleUpdated: (newRole) {
          pageContext.read<UserManagementBloc>().add(
            UpdateUserRoleEvent(user.uid!, newRole),
          );
        },
      ),
    );
  }

  void _toggleUserStatus(UserEntity user, bool isActive) {
    if (user.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot update user: User ID is missing'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }
    
    context.read<UserManagementBloc>().add(
      UpdateUserStatusEvent(user.uid!, isActive),
    );
  }
}
