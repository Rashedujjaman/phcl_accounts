import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity status.
///
/// Provides:
/// - **Real-time Connectivity**: Stream of connection status changes
/// - **Connection Checks**: One-time connectivity verification
/// - **Network Type Detection**: WiFi, mobile data, or offline
///
/// Used to trigger sync operations when network becomes available.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream controller for broadcasting connectivity changes.
  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream subscription for connectivity changes.
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Current connectivity status.
  bool _isConnected = false;

  /// Gets whether device is currently connected to internet.
  bool get isConnected => _isConnected;

  /// Stream that emits true when online, false when offline.
  ///
  /// Subscribe to this stream to react to connectivity changes:
  /// ```dart
  /// connectivityService.connectionStream.listen((isOnline) {
  ///   if (isOnline) {
  ///     // Trigger sync
  ///   }
  /// });
  /// ```
  Stream<bool> get connectionStream => _connectivityController.stream;

  /// Initializes connectivity monitoring.
  ///
  /// Should be called once during app startup to begin monitoring
  /// network status changes.
  Future<void> initialize() async {
    // Check initial connectivity
    _isConnected = await checkConnection();

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        // Handle error gracefully
        _isConnected = false;
        _connectivityController.add(false);
      },
    );
  }

  /// Handles connectivity change events.
  ///
  /// Updates internal state and broadcasts changes to listeners.
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool wasConnected = _isConnected;
    _isConnected = _hasActiveConnection(results);

    // Only broadcast if status actually changed
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
    }
  }

  /// Checks if any of the connectivity results indicate an active connection.
  bool _hasActiveConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Performs a one-time connectivity check.
  ///
  /// Returns true if device has any active network connection
  /// (WiFi, mobile data, ethernet, etc.).
  ///
  /// Use this for one-time checks without subscribing to the stream.
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasActiveConnection(results);
    } catch (e) {
      // If check fails, assume offline
      return false;
    }
  }

  /// Disposes of resources used by the connectivity service.
  ///
  /// Should be called when the service is no longer needed to prevent
  /// memory leaks.
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
