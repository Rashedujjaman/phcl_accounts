import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

class EditUserRoleDialog extends StatefulWidget {
  final UserEntity user;
  final Function(String) onRoleUpdated;

  const EditUserRoleDialog({
    super.key,
    required this.user,
    required this.onRoleUpdated,
  });

  @override
  State<EditUserRoleDialog> createState() => _EditUserRoleDialogState();
}

class _EditUserRoleDialogState extends State<EditUserRoleDialog> {
  late String selectedRole;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.user.role ?? 'user';
  }

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
              'Edit User Role',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}'.trim(),
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
                _buildRoleRadio('admin', 'Admin', 'Full access to all features'),
                _buildRoleRadio('user', 'User', 'Standard user access'),
                _buildRoleRadio('viewer', 'Viewer', 'Read-only access'),
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
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRoleUpdated(selectedRole);
                  },
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
    );
  }

  Widget _buildRoleRadio(String value, String title, String description) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => selectedRole = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedRole == value 
                ? theme.colorScheme.primary 
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selectedRole == value 
              ? theme.colorScheme.primary.withValues(alpha: .1)
              : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedRole,
              onChanged: (newValue) => setState(() => selectedRole = newValue!),
              activeColor: theme.colorScheme.primary,
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
                          ? theme.colorScheme.primary 
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
}
