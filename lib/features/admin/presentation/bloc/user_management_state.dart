import 'package:equatable/equatable.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

class UserManagementLoaded extends UserManagementState {
  final List<UserEntity> allUsers;
  final List<UserEntity> filteredUsers;
  final String searchQuery;
  final String selectedRoleFilter;

  const UserManagementLoaded({
    required this.allUsers,
    required this.filteredUsers,
    required this.searchQuery,
    required this.selectedRoleFilter,
  });

  @override
  List<Object?> get props => [allUsers, filteredUsers, searchQuery, selectedRoleFilter];

  UserManagementLoaded copyWith({
    List<UserEntity>? allUsers,
    List<UserEntity>? filteredUsers,
    String? searchQuery,
    String? selectedRoleFilter,
  }) {
    return UserManagementLoaded(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoleFilter: selectedRoleFilter ?? this.selectedRoleFilter,
    );
  }
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserManagementUpdateLoading extends UserManagementState {
  const UserManagementUpdateLoading();
}

class UserManagementUpdateSuccess extends UserManagementState {
  final String message;

  const UserManagementUpdateSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserManagementUpdateError extends UserManagementState {
  final String message;

  const UserManagementUpdateError(this.message);

  @override
  List<Object?> get props => [message];
}
