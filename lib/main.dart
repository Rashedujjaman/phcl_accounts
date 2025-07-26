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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  
  runApp(MyApp(themeProvider: themeProvider));
}

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
              RepositoryProvider<AuthRepositoryImpl>(
                create: (context) => AuthRepositoryImpl(
                  firebaseAuth: FirebaseAuth.instance,
                  firestore: FirebaseFirestore.instance,
                  storage: FirebaseStorage.instance
                ),
              ),
              RepositoryProvider<DashboardRepository>(
                create: (context) => DashboardRepositoryImpl(
                  auth: FirebaseAuth.instance,
                  firestore: FirebaseFirestore.instance,
                ),
              ),
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
                BlocProvider(
                  create: (context) => AuthBloc(
                    signIn: SignIn(context.read<AuthRepositoryImpl>()),
                    signUp: SignUp(context.read<AuthRepositoryImpl>()),
                    signOut: SignOut(context.read<AuthRepositoryImpl>()),
                    getCurrentUser: GetCurrentUser(context.read<AuthRepositoryImpl>()),
                    updateUserProfile: UpdateUserProfile(context.read<AuthRepositoryImpl>()),
                  )..add(CheckAuthStatusEvent()),
                ),
                BlocProvider(
                  create: (context) => DashboardBloc(
                    getDashboardData: GetDashboardData(
                      context.read<DashboardRepository>(),
                    ),
                  )..add(LoadDashboardData()),
                ),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return const MainNavigation();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
