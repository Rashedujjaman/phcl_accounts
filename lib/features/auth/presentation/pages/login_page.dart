import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is AuthAuthenticated) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      SignInEvent(
                        _emailController.text,
                        _passwordController.text,
                      ),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:shimmer/shimmer.dart';

// class LoginPage extends StatelessWidget {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   LoginPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 24.0,
//               vertical: 32.0,
//             ),
//             child: Card(
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(32.0),
//                 child: BlocConsumer<AuthBloc, AuthState>(
//                   listener: (context, state) {
//                     if (state is AuthError) {
//                       ScaffoldMessenger.of(
//                         context,
//                       ).showSnackBar(SnackBar(content: Text(state.message)));
//                     }
//                     if (state is AuthAuthenticated) {
//                       Navigator.pushReplacementNamed(context, '/dashboard');
//                     }
//                   },
//                   builder: (context, state) {
//                     if (state is AuthLoading) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     return Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Company Logo
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 24.0),
//                           child: SizedBox(
//                             height: 80,
//                             child: CachedNetworkImage(
//                               imageUrl:
//                                   'https://phclbd.com/wp-content/uploads/2025/03/cropped-Untitled_design__19_-removebg-preview-e1742456418321.png',
//                               placeholder:
//                                   (context, url) => Shimmer.fromColors(
//                                     baseColor: Colors.grey[300]!,
//                                     highlightColor: Colors.grey[100]!,
//                                     child: Container(
//                                       width: 80,
//                                       height: 80,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                               errorWidget:
//                                   (context, url, error) =>
//                                       const Icon(Icons.error),
//                             ),
//                           ),
//                         ),
//                         Text(
//                           'Welcome to PHCL Login Portal',
//                           style: Theme.of(
//                             context,
//                           ).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blueGrey[800],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 32),
//                         TextField(
//                           controller: _emailController,
//                           decoration: InputDecoration(
//                             labelText: 'Email',
//                             prefixIcon: const Icon(Icons.email_outlined),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           keyboardType: TextInputType.emailAddress,
//                         ),
//                         const SizedBox(height: 20),
//                         TextField(
//                           controller: _passwordController,
//                           decoration: InputDecoration(
//                             labelText: 'Password',
//                             prefixIcon: const Icon(Icons.lock_outline),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           obscureText: true,
//                         ),
//                         const SizedBox(height: 16),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {
//                               Navigator.pushNamed(context, '/reset-password');
//                             },
//                             child: const Text(
//                               'Forgot Password?',
//                               style: TextStyle(color: Colors.blue),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               side: BorderSide(
//                                 color: Theme.of(context).colorScheme.primary,
//                                 width: 2,
//                               ),
//                             ),
//                             onPressed: () {
//                               context.read<AuthBloc>().add(
//                                 SignInEvent(
//                                   _emailController.text,
//                                   _passwordController.text,
//                                 ),
//                               );
//                             },
//                             child: const Text(
//                               'Login',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
