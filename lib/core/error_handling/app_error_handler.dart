import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Simple error handling wrapper for the app
class AppErrorHandler {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
      
      // You can also log to a crash reporting service here
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Catch Dart errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      print('Dart Error: $error');
      print('Stack trace: $stack');
      
      // You can also log to a crash reporting service here
      // FirebaseCrashlytics.instance.recordError(error, stack);
      
      return true; // Indicates the error was handled
    };
  }

  static Widget wrapWithErrorBoundary(Widget child) {
    return ErrorBoundary(child: child);
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error Occurred'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage ?? 'An unexpected error occurred',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hasError = false;
                      errorMessage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // This doesn't actually catch widget build errors, but serves as a placeholder
    // For real error boundary functionality, you'd need to use a package like
    // flutter_error_boundary or implement custom error handling
  }
}
