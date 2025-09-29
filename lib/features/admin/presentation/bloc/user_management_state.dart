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

class UsersLoading extends UserManagementState {
  const UsersLoading();
}

class UsersLoaded extends UserManagementState {
  final List<UserEntity> allUsers;
  final List<UserEntity> filteredUsers;
  final String searchQuery;
  final String selectedRoleFilter;

  const UsersLoaded({
    required this.allUsers,
    required this.filteredUsers,
    required this.searchQuery,
    required this.selectedRoleFilter,
  });

  @override
  List<Object?> get props => [allUsers, filteredUsers, searchQuery, selectedRoleFilter];

  UsersLoaded copyWith({
    List<UserEntity>? allUsers,
    List<UserEntity>? filteredUsers,
    String? searchQuery,
    String? selectedRoleFilter,
  }) {
    return UsersLoaded(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoleFilter: selectedRoleFilter ?? this.selectedRoleFilter,
    );
  }
}

class UsersLoadingError extends UserManagementState {
  final String message;

  const UsersLoadingError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserRoleUpdateError extends UserManagementState {
  final String message;

  const UserRoleUpdateError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserStatusUpdateError extends UserManagementState {
  final String message;

  const UserStatusUpdateError(this.message);

  @override
  List<Object?> get props => [message];
}
