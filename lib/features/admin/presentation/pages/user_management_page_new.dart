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
    // Add a small delay to ensure the BLoC is properly initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<UserManagementBloc>().add(const LoadAllUsers());
      } catch (e) {
        print('Error initializing user management: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing user management: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey[800],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: BlocConsumer<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is UserManagementUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is UserManagementUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is UserManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserManagementLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is UserManagementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
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
          
          if (state is UserManagementLoaded) {
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
                          padding: const EdgeInsets.all(16),
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
            child: Text('Unknown state'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery, String roleFilter) {
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(UserEntity user) {
    try {
      if (user.uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User information is not available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => UserDetailsDialog(user: user),
      );
    } catch (e) {
      print('Error showing user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error displaying user details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditUserDialog(UserEntity user) {
    try {
      if (user.uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot edit user: User ID is missing'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => EditUserRoleDialog(
          user: user,
          onRoleUpdated: (newRole) {
            try {
              context.read<UserManagementBloc>().add(
                UpdateUserRoleEvent(user.uid!, newRole),
              );
            } catch (e) {
              print('Error updating user role: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating user role: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      print('Error showing edit dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error displaying edit dialog: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleUserStatus(UserEntity user, bool isActive) {
    try {
      if (user.uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot update user: User ID is missing'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      context.read<UserManagementBloc>().add(
        UpdateUserStatusEvent(user.uid!, isActive),
      );
    } catch (e) {
      print('Error toggling user status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
