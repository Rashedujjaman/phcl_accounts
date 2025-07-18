import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:phcl_accounts/core/widgets/main_navigation.dart';
import 'package:phcl_accounts/features/admin/presentation/pages/user_management_page.dart';
import 'package:phcl_accounts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_in.dart';
import 'package:phcl_accounts/features/auth/domain/usecases/sign_up.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:phcl_accounts/features/auth/presentation/pages/login_page.dart';
import 'package:phcl_accounts/features/auth/presentation/pages/register_page.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(
            firebaseAuth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
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
        )),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              signIn: SignIn(context.read<AuthRepositoryImpl>()),
              signUp: SignUp(context.read<AuthRepositoryImpl>()),
            )..add(CheckAuthStatusEvent()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              getDashboardData: GetDashboardData(
                context.read<DashboardRepository>(),
              ),
            ),
          ),
          BlocProvider(
            create: (context) => TransactionBloc(
              context.read<TransactionRepository>(),
            )
          ),
        ],
        child: MaterialApp(
          title: 'PHCL Accounts',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => LoginPage(),
            '/register': (context) => RegisterPage(),
            '/main-navigation': (context) => const MainNavigation(),
            '/user-management': (context) => const UserManagementPage(),
          },
        ),
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
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            return const MainNavigation();
          }
          return LoginPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}