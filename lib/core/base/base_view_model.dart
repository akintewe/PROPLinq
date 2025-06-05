import 'package:flutter/foundation.dart';

/// Base ViewModel class that provides common functionality for all ViewModels
/// Uses ChangeNotifier for state management
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  /// Loading state getter
  bool get isLoading => _isLoading;

  /// Error message getter
  String? get errorMessage => _errorMessage;

  /// Check if the ViewModel has been disposed
  bool get isDisposed => _isDisposed;

  /// Set loading state
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    if (_isDisposed) return;
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Show loading and clear any previous errors
  void showLoading() {
    clearError();
    setLoading(true);
  }

  /// Hide loading
  void hideLoading() {
    setLoading(false);
  }

  /// Handle errors in async operations
  Future<T?> handleAsync<T>(Future<T> operation) async {
    try {
      showLoading();
      final result = await operation;
      hideLoading();
      return result;
    } catch (e) {
      hideLoading();
      setError(e.toString());
      return null;
    }
  }

  /// Safe notifyListeners that checks if disposed
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Initialize method to be overridden by child ViewModels
  void initialize() {}

  /// Method to refresh data - to be overridden by child ViewModels
  Future<void> refresh() async {}
} 