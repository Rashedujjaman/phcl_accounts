import 'package:flutter/material.dart';
import 'package:phcl_accounts/features/admin/dependency_injection.dart';
import 'package:phcl_accounts/features/admin/presentation/pages/user_management_page.dart';

class UserManagementWrapper extends StatelessWidget {
  const UserManagementWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return createUserManagementBlocProvider(
      child: const UserManagementPage(),
    );
  }
}
