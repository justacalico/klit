import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service for authentication operations
class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final activeAccount = await _storageService.getActiveAccount();
    return activeAccount != null;
  }

  /// Get the active account
  Future<Account?> getActiveAccount() async {
    return await _storageService.getActiveAccount();
  }

  /// Get all accounts
  Future<List<Account>> getAccounts() async {
    return await _storageService.getAccounts();
  }

  /// Login with credentials
  Future<ApiResult<Account>> login({
    required String username,
    required String apiKey,
    String? host,
  }) async {
    // Use provided host, or default to e926.net for new account logins
    final targetHost = host ?? 'https://e926.net';
    if (kDebugMode) {
      print('AuthService.login: username=$username');
      print(
        'AuthService.login: apiKey=${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}',
      );
      print('AuthService.login: host=$host, targetHost=$targetHost');
    }
    _apiService.setBaseUrl(targetHost);

    // Verify credentials
    if (kDebugMode) {
      print('AuthService.login: Calling verifyCredentials...');
    }
    final result = await _apiService.verifyCredentials(username, apiKey);

    return result.when(
      success: (_) async {
        if (kDebugMode) {
          print('AuthService.login: Credentials verified successfully!');
          print('AuthService.login: Adding account to storage...');
        }
        // Add account to storage
        try {
          final account = await _storageService.addAccount(
            username: username,
            apiKey: apiKey,
            host: targetHost,
          );
          if (kDebugMode) {
            print('AuthService.login: Account added to storage!');
            print('AuthService.login: Account ID=${account.id}');
            print('AuthService.login: Account username=${account.username}');
            print('AuthService.login: Account host=${account.host}');
          }

          // Set up API service with auth
          if (kDebugMode) {
            print('AuthService.login: Setting up API service auth...');
          }
          _apiService.setAuth(username, apiKey);
          if (kDebugMode) {
            print('AuthService.login: API service auth set!');
          }

          // Verify account was actually saved
          final savedAccounts = await _storageService.getAccounts();
          if (kDebugMode) {
            print('AuthService.login: Verification - Total accounts in storage=${savedAccounts.length}');
            for (var i = 0; i < savedAccounts.length; i++) {
              print('AuthService.login: Saved Account[$i]: id=${savedAccounts[i].id}, username=${savedAccounts[i].username}');
            }
            final activeAccount = await _storageService.getActiveAccount();
            print('AuthService.login: Active account ID=${activeAccount?.id}');
            print('AuthService.login: Active account username=${activeAccount?.username}');
          }

          return ApiResult.success(account);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('AuthService.login: ERROR adding account to storage!');
            print('AuthService.login: Exception=$e');
            print('AuthService.login: StackTrace=$stackTrace');
          }
          return ApiResult.failure(ApiException.unknown(e));
        }
      },
      failure: (error) {
        if (kDebugMode) {
          print('AuthService.login: Credential verification FAILED!');
          print('AuthService.login: Error=${error.message}');
        }
        return ApiResult.failure(error);
      },
    );
  }

  /// Switch to a different account
  Future<ApiResult<Account>> switchAccount(String accountId) async {
    final accounts = await _storageService.getAccounts();
    final account = accounts.where((a) => a.id == accountId).firstOrNull;

    if (account == null) {
      return ApiResult.failure(ApiException.notFound('Account'));
    }

    // Update active account
    await _storageService.setActiveAccountId(accountId);

    // Update API service
    _apiService.setBaseUrl(account.host);
    _apiService.setAuth(account.username, account.apiKey);

    return ApiResult.success(account);
  }

  /// Remove an account
  Future<void> removeAccount(String accountId) async {
    await _storageService.removeAccount(accountId);

    // Check if there's still an active account
    final activeAccount = await _storageService.getActiveAccount();
    if (activeAccount != null) {
      _apiService.setBaseUrl(activeAccount.host);
      _apiService.setAuth(activeAccount.username, activeAccount.apiKey);
    } else {
      _apiService.clearAuth();
    }
  }

  /// Logout (remove active account)
  Future<void> logout() async {
    final activeAccount = await _storageService.getActiveAccount();
    if (activeAccount != null) {
      await removeAccount(activeAccount.id);
    }
  }

  /// Initialize auth from stored credentials
  Future<Account?> initializeAuth() async {
    final activeAccount = await _storageService.getActiveAccount();
    if (activeAccount != null) {
      _apiService.setBaseUrl(activeAccount.host);
      _apiService.setAuth(activeAccount.username, activeAccount.apiKey);
      return activeAccount;
    }
    return null;
  }
}
