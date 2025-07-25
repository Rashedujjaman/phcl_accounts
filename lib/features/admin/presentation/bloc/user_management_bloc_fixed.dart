import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phcl_accounts/features/admin/domain/usecases/get_all_users.dart';
import 'package:phcl_accounts/features/admin/domain/usecases/update_user_role.dart';
import 'package:phcl_accounts/features/admin/domain/usecases/update_user_status.dart';
import 'package:phcl_accounts/features/admin/presentation/bloc/user_management_event.dart';
import 'package:phcl_accounts/features/admin/presentation/bloc/user_management_state.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final GetAllUsers _getAllUsers;
  final UpdateUserRole _updateUserRole;
  final UpdateUserStatus _updateUserStatus;
  
  StreamSubscription<List<UserEntity>>? _usersSubscription;

  UserManagementBloc({
    required GetAllUsers getAllUsers,
    required UpdateUserRole updateUserRole,
    required UpdateUserStatus updateUserStatus,
  })  : _getAllUsers = getAllUsers,
        _updateUserRole = updateUserRole,
        _updateUserStatus = updateUserStatus,
        super(const UserManagementInitial()) {
    on<LoadAllUsers>(_onLoadAllUsers);
    on<SearchUsers>(_onSearchUsers);
    on<FilterUsersByRole>(_onFilterUsersByRole);
    on<UpdateUserRoleEvent>(_onUpdateUserRole);
    on<UpdateUserStatusEvent>(_onUpdateUserStatus);
  }

  void _onLoadAllUsers(LoadAllUsers event, Emitter<UserManagementState> emit) {
    try {
      emit(const UserManagementLoading());
      
      _usersSubscription?.cancel();
      _usersSubscription = _getAllUsers().listen(
        (users) {
          try {
            emit(UserManagementLoaded(
              allUsers: users,
              filteredUsers: users,
              searchQuery: '',
              selectedRoleFilter: 'all',
            ));
          } catch (e) {
            print('Error emitting loaded state: $e');
            emit(UserManagementError('Error processing users: $e'));
          }
        },
        onError: (error, stackTrace) {
          print('Stream subscription error: $error');
          print('Stack trace: $stackTrace');
          emit(UserManagementError('Failed to load users: $error'));
        },
      );
    } catch (e) {
      print('Error in _onLoadAllUsers: $e');
      emit(UserManagementError('Failed to initialize user loading: $e'));
    }
  }

  void _onSearchUsers(SearchUsers event, Emitter<UserManagementState> emit) {
    if (state is UserManagementLoaded) {
      final currentState = state as UserManagementLoaded;
      final filteredUsers = _filterUsers(
        currentState.allUsers,
        event.query,
        currentState.selectedRoleFilter,
      );
      
      emit(currentState.copyWith(
        filteredUsers: filteredUsers,
        searchQuery: event.query,
      ));
    }
  }

  void _onFilterUsersByRole(FilterUsersByRole event, Emitter<UserManagementState> emit) {
    if (state is UserManagementLoaded) {
      final currentState = state as UserManagementLoaded;
      final filteredUsers = _filterUsers(
        currentState.allUsers,
        currentState.searchQuery,
        event.role,
      );
      
      emit(currentState.copyWith(
        filteredUsers: filteredUsers,
        selectedRoleFilter: event.role,
      ));
    }
  }

  Future<void> _onUpdateUserRole(UpdateUserRoleEvent event, Emitter<UserManagementState> emit) async {
    try {
      await _updateUserRole(event.userId, event.newRole);
      emit(const UserManagementUpdateSuccess('User role updated successfully'));
    } catch (error) {
      emit(UserManagementUpdateError('Failed to update user role: $error'));
    }
  }

  Future<void> _onUpdateUserStatus(UpdateUserStatusEvent event, Emitter<UserManagementState> emit) async {
    try {
      await _updateUserStatus(event.userId, event.isActive);
      emit(UserManagementUpdateSuccess(
        'User ${event.isActive ? 'activated' : 'deactivated'} successfully',
      ));
    } catch (error) {
      emit(UserManagementUpdateError('Failed to update user status: $error'));
    }
  }

  List<UserEntity> _filterUsers(List<UserEntity> users, String searchQuery, String roleFilter) {
    try {
      return users.where((user) {
        // Role filter
        if (roleFilter != 'all' && user.role != roleFilter) {
          return false;
        }
        
        // Search filter
        if (searchQuery.isNotEmpty) {
          final firstName = (user.firstName ?? '').toLowerCase();
          final lastName = (user.lastName ?? '').toLowerCase();
          final email = (user.email ?? '').toLowerCase();
          final fullName = '$firstName $lastName';
          final query = searchQuery.toLowerCase();
          
          return fullName.contains(query) || 
                 email.contains(query) ||
                 firstName.contains(query) ||
                 lastName.contains(query);
        }
        
        return true;
      }).toList();
    } catch (e) {
      print('Error filtering users: $e');
      return users; // Return unfiltered list if filtering fails
    }
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}
