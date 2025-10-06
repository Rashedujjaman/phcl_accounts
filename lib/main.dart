// PHCL Accounts - Main Entry Point
// --------------------------------------------------
// This file bootstraps the Flutter application, sets up core providers,
// initializes Firebase, configures theme management, and wires up
// dependency injection and state management using BLoC and Provider.
//
// Architecture: Clean Architecture (Domain/Data/Presentation layers)
// State Management: BLoC (flutter_bloc), Provider
// Backend: Firebase (Auth, Firestore, Storage)
// --------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:phcl_accounts/core/theme/app_themes.dart';
import 'package:phcl_accounts/core/theme/theme_provider.dart';
import 'package:phcl_accounts/core/widgets/main_navigation.dart';
import 'package:phcl_accounts/features/admin/presentation/pages/user_management_wrapper.dart';
import 'package:phcl_accounts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/get_current_user.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_in.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_up.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_out.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/update_user_profile.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:phcl_accounts/features/auth/presentation/pages/login_page.dart';
import 'package:phcl_accounts/features/auth/presentation/pages/register_page.dart';
import 'package:phcl_accounts/features/auth/presentation/pages/reset_password.dart';
import 'package:phcl_accounts/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:phcl_accounts/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:phcl_accounts/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:phcl_accounts/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:phcl_accounts/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:phcl_accounts/features/transactions/presentation/bloc/transaction_bloc.dart';

/// Main entry point for PHCL Accounts app.
/// Initializes Flutter bindings, Firebase, and theme provider before launching the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ThemeProvider manages light/dark mode and persists user preference.
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(MyApp(themeProvider: themeProvider));
}

/// Root widget for the application.
/// Sets up dependency injection (RepositoryProvider), state management (BlocProvider),
/// and theme management (ChangeNotifierProvider).
class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MultiRepositoryProvider(
            providers: [
              // AuthRepositoryImpl: Handles authentication and user profile operations.
              RepositoryProvider<AuthRepositoryImpl>(
                create: (context) => AuthRepositoryImpl(
                  firebaseAuth: FirebaseAuth.instance,
                  firestore: FirebaseFirestore.instance,
                  storage: FirebaseStorage.instance
                ),
              ),
              // DashboardRepository: Handles analytics and dashboard data.
              RepositoryProvider<DashboardRepository>(
                create: (context) => DashboardRepositoryImpl(
                  auth: FirebaseAuth.instance,
                  firestore: FirebaseFirestore.instance,
                ),
              ),
              // TransactionRepository: Handles CRUD operations for financial transactions.
              RepositoryProvider<TransactionRepository>(
                create: (context) => TransactionRepositoryImpl(
                  firestore: FirebaseFirestore.instance,
                  storage: FirebaseStorage.instance,
                  auth: FirebaseAuth.instance,
                ),
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                // AuthBloc: Manages authentication state and user session.
                BlocProvider(
                  create: (context) => AuthBloc(
                    signIn: SignIn(context.read<AuthRepositoryImpl>()),
                    signUp: SignUp(context.read<AuthRepositoryImpl>()),
                    signOut: SignOut(context.read<AuthRepositoryImpl>()),
                    getCurrentUser: GetCurrentUser(context.read<AuthRepositoryImpl>()),
                    updateUserProfile: UpdateUserProfile(context.read<AuthRepositoryImpl>()),
                  )..add(CheckAuthStatusEvent()),
                ),
                // DashboardBloc: Manages dashboard analytics and chart data.
                BlocProvider(
                  create: (context) => DashboardBloc(
                    getDashboardData: GetDashboardData(
                      context.read<DashboardRepository>(),
                    ),
                  ),
                ),
                // TransactionBloc: Handles transaction list, creation, and updates.
                BlocProvider(
                  create: (context) =>
                      TransactionBloc(context.read<TransactionRepository>()),
                ),
              ],
              child: MaterialApp(
                title: 'PHCL Accounts',
                debugShowCheckedModeBanner: false,
                themeMode: themeProvider.themeMode,
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                home: const AuthWrapper(),
                routes: {
                  '/login': (context) => LoginPage(),
                  '/register': (context) => RegisterPage(),
                  '/reset-password': (context) => ResetPasswordPage(),
                  '/main-navigation': (context) => MainNavigation(),
                  '/user-management': (context) => UserManagementWrapper(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AuthWrapper: Decides which screen to show based on authentication state.
/// Shows MainNavigation if user is authenticated, otherwise shows LoginPage.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while checking auth state.
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // User is authenticated, show main navigation.
          return const MainNavigation();
        } else {
          // User is not authenticated, show login page.
          return LoginPage();
        }
      },
    );
  }
}
