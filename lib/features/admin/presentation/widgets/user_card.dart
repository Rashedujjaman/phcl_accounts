import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

class UserCard extends StatelessWidget {
  final UserEntity user;
  final VoidCallback? onEditRole;
  final VoidCallback? onViewDetails;
  final Function(bool)? onToggleStatus;

  const UserCard({
    super.key,
    required this.user,
    this.onEditRole,
    this.onViewDetails,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: _getRoleColor(user.role ?? 'user').withOpacity(0.2),
                  child: Text(
                    _getInitials(user.firstName ?? '', user.lastName ?? ''),
                    style: TextStyle(
                      color: _getRoleColor(user.role ?? 'user'),
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
                        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ?? '',
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
                      value: user.isActive ?? true,
                      onChanged: onToggleStatus,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                    ),
                    Text(
                      (user.isActive ?? true) ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: (user.isActive ?? true) ? Colors.green : Colors.grey,
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
                if (user.contactNo?.isNotEmpty == true) ...[
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    user.contactNo!,
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
                  _formatDate(user.createdAt),
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
                    color: _getRoleColor(user.role ?? 'user').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRoleColor(user.role ?? 'user').withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    (user.role ?? 'user').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(user.role ?? 'user'),
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
                  onPressed: onEditRole,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Role'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onViewDetails,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
