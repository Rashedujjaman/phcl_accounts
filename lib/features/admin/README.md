# User Management Clean Architecture

This document explains how the user management feature has been refactored to follow Clean Architecture principles with proper BLoC state management.

## 📁 Folder Structure

```
lib/features/admin/
├── data/
│   └── repositories/
│       └── user_management_repository_impl.dart
├── domain/
│   ├── repositories/
│   │   └── user_management_repository.dart
│   └── usecases/
│       ├── get_all_users.dart
│       ├── update_user_role.dart
│       └── update_user_status.dart
├── presentation/
│   ├── bloc/
│   │   ├── user_management_bloc.dart
│   │   ├── user_management_event.dart
│   │   └── user_management_state.dart
│   ├── pages/
│   │   ├── user_management_page_new.dart
│   │   └── user_management_wrapper.dart
│   └── widgets/
│       ├── user_card.dart
│       ├── search_and_filter_widget.dart
│       ├── user_details_dialog.dart
│       └── edit_user_role_dialog.dart
└── dependency_injection.dart
```

## 🏗️ Architecture Layers

### 1. Domain Layer (Business Logic)
- **Repository Interface**: `UserManagementRepository`
- **Use Cases**: 
  - `GetAllUsers`: Streams all users from Firestore
  - `UpdateUserRole`: Updates a user's role
  - `UpdateUserStatus`: Activates/deactivates users

### 2. Data Layer (External Data Sources)
- **Repository Implementation**: `UserManagementRepositoryImpl`
- Handles Firebase Firestore operations
- Converts Firestore documents to `UserEntity` objects

### 3. Presentation Layer (UI & State Management)
- **BLoC**: `UserManagementBloc` for state management
- **Pages**: Clean, focused page components
- **Widgets**: Reusable UI components
- **Events & States**: Proper state management architecture

## 🔄 State Management Flow

```
UI Event → BLoC Event → Use Case → Repository → Firestore
                                                    ↓
UI State ← BLoC State ← Stream/Result ←─────────────┘
```

## 🚀 How to Use

### 1. Replace the old user management page in your routes:

```dart
// Old way
'/user-management': (context) => UserManagementPage(),

// New way
'/user-management': (context) => UserManagementWrapper(),
```

### 2. The wrapper handles all dependency injection automatically

### 3. Features Available:
- ✅ Real-time user data streaming
- ✅ Search users by name/email
- ✅ Filter users by role
- ✅ Edit user roles with beautiful dialog
- ✅ Toggle user active/inactive status
- ✅ View detailed user information
- ✅ Proper error handling and loading states
- ✅ Clean, modern UI with Material Design

## 📋 BLoC Events

```dart
// Load all users
context.read<UserManagementBloc>().add(LoadAllUsers());

// Search users
context.read<UserManagementBloc>().add(SearchUsers('query'));

// Filter by role
context.read<UserManagementBloc>().add(FilterUsersByRole('admin'));

// Update user role
context.read<UserManagementBloc>().add(UpdateUserRoleEvent(userId, newRole));

// Update user status
context.read<UserManagementBloc>().add(UpdateUserStatusEvent(userId, isActive));
```

## 🎯 Benefits of This Architecture

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Easy to unit test use cases and BLoC logic
3. **Maintainability**: Changes in one layer don't affect others
4. **Scalability**: Easy to add new features following the same pattern
5. **Reusability**: Widgets and use cases can be reused elsewhere
6. **State Management**: Proper BLoC pattern with reactive UI
7. **Error Handling**: Centralized error handling in BLoC

## 🔧 Dependencies

Make sure these are in your `pubspec.yaml`:
```yaml
dependencies:
  flutter_bloc: ^9.1.1
  bloc: ^9.0.0
  equatable: ^2.0.7
  cloud_firestore: ^5.6.11
```

## 🎨 UI Components

- **UserCard**: Displays user information with actions
- **SearchAndFilterWidget**: Handles search and role filtering
- **UserDetailsDialog**: Shows comprehensive user information
- **EditUserRoleDialog**: Beautiful role selection dialog

All components follow Material Design principles with proper spacing, colors, and animations.
