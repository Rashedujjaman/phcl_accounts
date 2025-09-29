import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

class UserDetailsDialog extends StatelessWidget {
  final UserEntity user;

  const UserDetailsDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            _buildDetailRow(context, 'Name', '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()),
            _buildDetailRow(context, 'Email', user.email ?? 'N/A'),
            _buildDetailRow(context, 'Contact', user.contactNo ?? 'N/A'),
            _buildDetailRow(context, 'Role', user.role ?? 'N/A'),
            _buildDetailRow(context, 'Status', (user.isActive ?? true) ? 'Active' : 'Inactive'),
            _buildDetailRow(context, 'Created', _formatDate(user.createdAt)),
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
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
