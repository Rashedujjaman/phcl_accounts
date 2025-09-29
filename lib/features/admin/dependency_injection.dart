import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phcl_accounts/features/admin/data/repositories/user_management_repository_impl.dart';
import 'package:phcl_accounts/features/admin/domain/repositories/user_management_repository.dart';
import 'package:phcl_accounts/features/admin/domain/usecases/get_all_users.dart';
import 'package:phcl_accounts/features/admin/domain/usecases/update_user_role.dart';
import 'package:phcl_accounts/features/admin/domain/usecases/update_user_status.dart';
import 'package:phcl_accounts/features/admin/presentation/bloc/user_management_bloc.dart';

Widget createUserManagementBlocProvider({required Widget child}) {
  // Repository
  final UserManagementRepository repository = UserManagementRepositoryImpl(
    FirebaseFirestore.instance,
  );

  // Use cases
  final getAllUsers = GetAllUsers(repository);
  final updateUserRole = UpdateUserRole(repository);
  final updateUserStatus = UpdateUserStatus(repository);

  return BlocProvider<UserManagementBloc>(
    create: (context) => UserManagementBloc(
      getAllUsers: getAllUsers,
      updateUserRole: updateUserRole,
      updateUserStatus: updateUserStatus,
    ),
    child: child,
  );
}
