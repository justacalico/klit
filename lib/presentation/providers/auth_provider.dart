import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';

/// Provider for authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  ApiService? _apiService;

  Account? _currentAccount;
  List<Account> _accounts = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isGuest = false;

  AuthProvider({required AuthService authService}) : _authService = authService;

  /// Set the API service reference (call after creation)
  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  // Getters
  Account? get currentAccount => _currentAccount;
  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentAccount != null || _isGuest;
  bool get isGuest => _isGuest;
  bool get isInitialized => _isInitialized;

  /// Initialize authentication state
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    // Don't notify during initial load to avoid build-time errors

    try {
      _currentAccount = await _authService.initializeAuth();
      _accounts = await _authService.getAccounts();
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
    }
  }

  /// Login with credentials
  Future<bool> login({
    required String username,
    required String apiKey,
    String? host,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(
      username: username,
      apiKey: apiKey,
      host: host,
    );

    return result.when(
      success: (account) async {
        _currentAccount = account;
        _accounts = await _authService.getAccounts();
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (error) {
        _error = error.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  /// Switch to a different account
  Future<bool> switchAccount(String accountId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.switchAccount(accountId);

    return result.when(
      success: (account) {
        _currentAccount = account;
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (error) {
        _error = error.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  /// Remove an account
  /// Returns true if there are no more accounts (should navigate to login)
  Future<bool> removeAccount(String accountId) async {
    _isLoading = true;
    notifyListeners();

    await _authService.removeAccount(accountId);
    _accounts = await _authService.getAccounts();

    if (_currentAccount?.id == accountId) {
      // Current account was removed, switch to another if available
      if (_accounts.isNotEmpty) {
        _currentAccount = _accounts.first;
        // Update API service with new account's credentials
        _apiService?.setBaseUrl(_currentAccount!.host);
        _apiService?.setAuth(_currentAccount!.username, _currentAccount!.apiKey);
      } else {
        _currentAccount = null;
        _apiService?.clearAuth();
      }
    }

    _isLoading = false;
    notifyListeners();

    // Return true if no accounts left
    return _accounts.isEmpty && _currentAccount == null;
  }

  /// Logout current account only (keeps other accounts)
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _accounts = await _authService.getAccounts();
    _currentAccount = _accounts.isNotEmpty ? _accounts.first : null;
    _isGuest = false;

    _isLoading = false;
    notifyListeners();
  }

  /// Check if there are any accounts
  bool get hasAccounts => _accounts.isNotEmpty;

  /// Continue as guest (no account required)
  /// Guest mode uses e621.net with forced safe mode
  void continueAsGuest() {
    _isGuest = true;
    _isInitialized = true;
    // Set API to use e621.net for guest mode (e926 has Cloudflare issues)
    _apiService?.setBaseUrl(ApiConstants.nsfwHost);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
