import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _selectedRoleFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
      body: Column(
        children: [
          _buildFilterAndSearch(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                          snapshot.error.toString(),
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first user to get started',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final filteredUsers = _filterUsers(snapshot.data!.docs);

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No users match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildFilterAndSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Users'),
                const SizedBox(width: 8),
                _buildFilterChip('admin', 'Admins'),
                const SizedBox(width: 8),
                _buildFilterChip('user', 'Users'),
                const SizedBox(width: 8),
                _buildFilterChip('viewer', 'Viewers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedRoleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRoleFilter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Stream<QuerySnapshot> _getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<DocumentSnapshot> _filterUsers(List<DocumentSnapshot> users) {
    return users.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      
      // Role filter
      if (_selectedRoleFilter != 'all' && userData['role'] != _selectedRoleFilter) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final firstName = (userData['firstName'] ?? '').toString().toLowerCase();
        final lastName = (userData['lastName'] ?? '').toString().toLowerCase();
        final email = (userData['email'] ?? '').toString().toLowerCase();
        final fullName = '$firstName $lastName';
        
        return fullName.contains(_searchQuery) || 
               email.contains(_searchQuery) ||
               firstName.contains(_searchQuery) ||
               lastName.contains(_searchQuery);
      }
      
      return true;
    }).toList();
  }

  Widget _buildUserCard(DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final email = userData['email'] ?? '';
    final role = userData['role'] ?? 'user';
    final isActive = userData['isActive'] ?? true;
    final contactNo = userData['contactNo'] ?? '';
    final createdAt = userData['createdAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(role).withOpacity(0.2),
                  child: Text(
                    _getInitials(firstName, lastName),
                    style: TextStyle(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Active Status Toggle
                Column(
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (value) => _toggleUserStatus(user, value),
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                    ),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details Row
            Row(
              children: [
                // Contact Number
                if (contactNo.isNotEmpty) ...[
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    contactNo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                // Creation Date
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                // Role Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRoleColor(role).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(role),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditUserDialog(context, user),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Role'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showUserDetails(context, user),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      case 'viewer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'Unknown';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _toggleUserStatus(DocumentSnapshot user, bool isActive) async {
    try {
      await user.reference.update({'isActive': isActive});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${isActive ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: isActive ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context, DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', '${userData['firstName']} ${userData['lastName']}'),
              _buildDetailRow('Email', userData['email'] ?? 'N/A'),
              _buildDetailRow('Contact', userData['contactNo'] ?? 'N/A'),
              _buildDetailRow('Role', userData['role'] ?? 'N/A'),
              _buildDetailRow('Status', userData['isActive'] == true ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(userData['createdAt'])),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    String selectedRole = userData['role'] ?? 'user';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit User Role',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${userData['firstName']} ${userData['lastName']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Role:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Role Selection
                Column(
                  children: [
                    _buildRoleRadio(
                      'admin',
                      'Admin',
                      'Full access to all features',
                      selectedRole,
                      (newRole) => setDialogState(() => selectedRole = newRole),
                    ),
                    _buildRoleRadio(
                      'user',
                      'User',
                      'Standard user access',
                      selectedRole,
                      (newRole) => setDialogState(() => selectedRole = newRole),
                    ),
                    _buildRoleRadio(
                      'viewer',
                      'Viewer',
                      'Read-only access',
                      selectedRole,
                      (newRole) => setDialogState(() => selectedRole = newRole),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateUserRole(context, user, selectedRole),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Update Role'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleRadio(String value, String title, String description, 
      String selectedRole, Function(String) onRoleChanged) {
    return InkWell(
      onTap: () => onRoleChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedRole == value 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selectedRole == value 
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedRole,
              onChanged: (newValue) => onRoleChanged(newValue!),
              activeColor: Theme.of(context).primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: selectedRole == value 
                          ? Theme.of(context).primaryColor 
                          : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateUserRole(BuildContext context, DocumentSnapshot user, String newRole) async {
    try {
      await user.reference.update({'role': newRole});
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to $newRole successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user role: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}