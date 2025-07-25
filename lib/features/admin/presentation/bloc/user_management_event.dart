import 'package:equatable/equatable.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllUsers extends UserManagementEvent {
  const LoadAllUsers();
}

class SearchUsers extends UserManagementEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterUsersByRole extends UserManagementEvent {
  final String role;

  const FilterUsersByRole(this.role);

  @override
  List<Object?> get props => [role];
}

class UpdateUserRoleEvent extends UserManagementEvent {
  final String userId;
  final String newRole;

  const UpdateUserRoleEvent(this.userId, this.newRole);

  @override
  List<Object?> get props => [userId, newRole];
}

class UpdateUserStatusEvent extends UserManagementEvent {
  final String userId;
  final bool isActive;

  const UpdateUserStatusEvent(this.userId, this.isActive);

  @override
  List<Object?> get props => [userId, isActive];
}
